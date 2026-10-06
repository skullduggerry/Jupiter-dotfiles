#!/usr/bin/env python3
"""XDG autostart for the Settings app's About page, Startup tab.

    autostart.py list               JSON: the entries this desktop starts, or
                                    would start if they were on
    autostart.py set ID on|off      switch one on or off
    autostart.py add APP_ID         autostart an installed app
    autostart.py remove ID          delete an entry only the user's folder has

uwsm hands autostart to systemd-xdg-autostart-generator, so what "starts" means
is decided the way the generator decides: a file in ~/.config/autostart masks
the system's of the same name; Hidden, X-systemd-skip, Type, Exec, TryExec and
OnlyShowIn/NotShowIn (against XDG_CURRENT_DESKTOP) count, and a GNOME startup
phase does on GNOME. X-GNOME-Autostart-enabled does not, so this never writes
it. The generator runs at login, which is when a change takes effect.

Switching off follows the autostart spec: Hidden=true, in a copy of the system
file when the user has none yet. Switching back on removes that copy again if
it differs from the system file in nothing else.
"""

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

GROUP = "Desktop Entry"


def config_home():
    return os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")


def user_dir():
    return os.path.join(config_home(), "autostart")


def system_dirs():
    dirs = os.environ.get("XDG_CONFIG_DIRS") or "/etc/xdg"
    return [os.path.join(d, "autostart") for d in dirs.split(":") if d]


def application_dirs():
    data_home = os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share")
    data_dirs = os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"
    return [os.path.join(d, "applications") for d in [data_home] + data_dirs.split(":") if d]


def read(path):
    with open(path, encoding="utf-8", errors="replace") as file:
        return file.read()


def parse(text):
    """The [Desktop Entry] group's keys, first occurrence winning."""
    keys, group = {}, None
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            group = line[1:-1]
        elif group == GROUP and "=" in line:
            key, value = line.split("=", 1)
            keys.setdefault(key.strip(), value.strip())
    return keys


def boolean(value):
    return (value or "").strip().lower() == "true"


def listed(value):
    return [item.strip().lower() for item in (value or "").split(";") if item.strip()]


def set_key(text, key, value):
    """Set key=value in the [Desktop Entry] group, keeping everything else."""
    lines = text.splitlines()
    group, start, end = None, None, len(lines)
    for index, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            if group == GROUP:
                end = index
                break
            group = stripped[1:-1]
            if group == GROUP:
                start = index
    if start is None:
        lines = ["[" + GROUP + "]"] + lines
        start, end = 0, len(lines)
    for index in range(start + 1, end):
        if re.match(r"\s*" + re.escape(key) + r"\s*=", lines[index]):
            lines[index] = key + "=" + value
            return "\n".join(lines) + "\n"
    # After the group's last non-blank line, so a blank line before the next
    # group stays where it was.
    insert = end
    while insert > start + 1 and not lines[insert - 1].strip():
        insert -= 1
    lines.insert(insert, key + "=" + value)
    return "\n".join(lines) + "\n"


def without_key(text, key):
    return [line for line in text.splitlines() if not re.match(r"\s*" + re.escape(key) + r"\s*=", line) and line.strip()]


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    handle, temporary = tempfile.mkstemp(dir=os.path.dirname(path), prefix=".autostart-")
    with os.fdopen(handle, "w", encoding="utf-8") as file:
        file.write(text)
    os.chmod(temporary, 0o644)
    os.replace(temporary, path)


def system_file(name):
    for directory in system_dirs():
        path = os.path.join(directory, name)
        if os.path.isfile(path):
            return path
    return None


def user_file(name):
    path = os.path.join(user_dir(), name)
    return path if os.path.isfile(path) else None


def on_path(program):
    return shutil.which(os.path.expanduser(program)) is not None


def starts_here(keys, desktops):
    """Whether the generator would start it, Hidden aside."""
    if keys.get("Type") != "Application" or not keys.get("Exec"):
        return False
    if boolean(keys.get("X-systemd-skip")):
        return False
    if keys.get("TryExec") and not on_path(keys["TryExec"]):
        return False
    only, never = listed(keys.get("OnlyShowIn")), listed(keys.get("NotShowIn"))
    if keys.get("X-GNOME-Autostart-Phase"):
        only = [desktop for desktop in only if desktop != "gnome"] if only else only
        never = never + ["gnome"]
        if not only and listed(keys.get("OnlyShowIn")):
            return False
    if only and not any(desktop in only for desktop in desktops):
        return False
    if any(desktop in never for desktop in desktops):
        return False
    return True


def unit_states():
    """Desktop file id -> the sub state of the unit the generator made for it."""
    try:
        out = subprocess.run(
            ["systemctl", "--user", "list-units", "--all", "--output=json", "app-*@autostart.service"],
            capture_output=True, text=True, timeout=5).stdout
        units = json.loads(out or "[]")
    except (OSError, ValueError, subprocess.TimeoutExpired):
        return {}
    states = {}
    for unit in units:
        match = re.fullmatch(r"app-(.*)@autostart\.service", unit.get("unit", ""))
        if match:
            name = re.sub(r"\\x([0-9a-fA-F]{2})", lambda hexa: chr(int(hexa.group(1), 16)), match.group(1))
            states[name] = unit.get("sub", "")
    return states


def entries():
    desktops = listed((os.environ.get("XDG_CURRENT_DESKTOP") or "").replace(":", ";"))
    names = set()
    for directory in [user_dir()] + system_dirs():
        if os.path.isdir(directory):
            names.update(name for name in os.listdir(directory) if name.endswith(".desktop"))
    states = unit_states()
    found = []
    for name in sorted(names):
        mine, theirs = user_file(name), system_file(name)
        path = mine or theirs
        keys = parse(read(path))
        if not starts_here(keys, desktops):
            continue
        ident = name[:-len(".desktop")]
        found.append({
            "id": ident,
            "name": keys.get("Name") or ident,
            "comment": keys.get("Comment") or keys.get("GenericName") or "",
            "icon": keys.get("Icon") or "",
            "exec": keys.get("Exec"),
            "enabled": not boolean(keys.get("Hidden")),
            # Only the user's folder has it: removing it is the way to undo it.
            "custom": theirs is None,
            "state": states.get(ident, ""),
        })
    return sorted(found, key=lambda entry: entry["name"].lower())


def switch(ident, enabled):
    name = ident + ".desktop"
    mine, theirs = user_file(name), system_file(name)
    if mine is None and theirs is None:
        raise SystemExit(f"autostart: no entry {ident}")
    if enabled:
        if mine is not None and theirs is not None and \
                without_key(read(mine), "Hidden") == without_key(read(theirs), "Hidden") and \
                not boolean(parse(read(theirs)).get("Hidden")):
            os.remove(mine)
        elif mine is not None:
            write(mine, set_key(read(mine), "Hidden", "false"))
        elif boolean(parse(read(theirs)).get("Hidden")):
            write(os.path.join(user_dir(), name), set_key(read(theirs), "Hidden", "false"))
    else:
        source = mine or theirs
        write(os.path.join(user_dir(), name), set_key(read(source), "Hidden", "true"))


def find_application(app_id):
    """The .desktop file a desktop entry id names, nested folders included."""
    for directory in application_dirs():
        direct = os.path.join(directory, app_id + ".desktop")
        if os.path.isfile(direct):
            return direct
        for root, _, files in os.walk(directory):
            for file in files:
                relative = os.path.relpath(os.path.join(root, file), directory)
                if relative.replace(os.sep, "-") == app_id + ".desktop":
                    return os.path.join(root, file)
    return None


def add(app_id):
    target = os.path.join(user_dir(), app_id + ".desktop")
    if os.path.isfile(target):
        switch(app_id, True)
        return
    source = find_application(app_id)
    if source is None:
        raise SystemExit(f"autostart: no application {app_id}")
    text = read(source)
    if boolean(parse(text).get("Hidden")):
        text = set_key(text, "Hidden", "false")
    write(target, text)


def remove(ident):
    name = ident + ".desktop"
    if system_file(name) is not None:
        raise SystemExit(f"autostart: {ident} is the system's; switch it off instead")
    mine = user_file(name)
    if mine is not None:
        os.remove(mine)


def main(argv):
    if argv[1:2] == ["list"]:
        json.dump(entries(), sys.stdout)
        print()
    elif argv[1:2] == ["set"] and len(argv) == 4 and argv[3] in ("on", "off"):
        switch(argv[2], argv[3] == "on")
    elif argv[1:2] == ["add"] and len(argv) == 3:
        add(argv[2])
    elif argv[1:2] == ["remove"] and len(argv) == 3:
        remove(argv[2])
    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main(sys.argv)
