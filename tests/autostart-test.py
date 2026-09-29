#!/usr/bin/env python3
"""The Settings app's autostart helper against a made-up set of folders.

It has to agree with systemd-xdg-autostart-generator, which is what starts
autostart apps under uwsm: which entries count on this desktop, a user file
masking the system one, Hidden= for off. And switching an entry off and on
again must leave nothing behind, while a user's own changes to an entry stay.
systemctl is a stand-in on PATH, reporting one unit running.
"""
import json
import os
import pathlib
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
HELPER = REPO / ".config" / "quickshell" / "settings" / "autostart.py"

failures = []


def check(condition, message):
    if not condition:
        failures.append(message)


def entry(name, *extra):
    return "\n".join(["[Desktop Entry]", "Type=Application", f"Name={name}", "Exec=true"] + list(extra)) + "\n"


def main():
    with tempfile.TemporaryDirectory() as tmp:
        root = pathlib.Path(tmp)
        system = root / "xdg" / "autostart"
        user = root / "config" / "autostart"
        apps = root / "data" / "applications"
        bin_dir = root / "bin"
        for directory in (system, apps, bin_dir):
            directory.mkdir(parents=True)

        (system / "plain.desktop").write_text(entry("Plain", "Comment=Starts everywhere"))
        (system / "kde-only.desktop").write_text(entry("KDE only", "OnlyShowIn=KDE;"))
        (system / "not-here.desktop").write_text(entry("Not here", "NotShowIn=Hyprland;GNOME;"))
        (system / "skipped.desktop").write_text(entry("Skipped", "X-systemd-skip=true"))
        (system / "phase.desktop").write_text(entry("Phase", "OnlyShowIn=GNOME;", "X-GNOME-Autostart-Phase=Initialization"))
        (system / "missing.desktop").write_text(entry("Missing", "TryExec=no-such-program-anywhere"))
        (system / "shipped-off.desktop").write_text(entry("Shipped off", "Hidden=true"))
        (system / "with-action.desktop").write_text(
            entry("With action") + "\n[Desktop Action new]\nName=New\nExec=true --new\n")
        (apps / "my-app.desktop").write_text(entry("My app", "Icon=my-icon"))

        systemctl = bin_dir / "systemctl"
        systemctl.write_text("#!/bin/sh\necho '[{\"unit\": \"app-plain@autostart.service\", \"sub\": \"running\"},"
                             " {\"unit\": \"app-with\\\\x2daction@autostart.service\", \"sub\": \"dead\"}]'\n")
        systemctl.chmod(0o755)

        env = dict(os.environ,
                   XDG_CONFIG_HOME=str(root / "config"), XDG_CONFIG_DIRS=str(root / "xdg"),
                   XDG_DATA_HOME=str(root / "data"), XDG_DATA_DIRS=str(root / "none"),
                   XDG_CURRENT_DESKTOP="Hyprland", PATH=f"{bin_dir}:{os.environ.get('PATH', '')}")

        def run(*args, ok=True):
            result = subprocess.run([sys.executable, str(HELPER), *args], env=env, capture_output=True, text=True)
            check((result.returncode == 0) == ok, f"{' '.join(args)}: exit {result.returncode} {result.stderr.strip()}")
            return result.stdout

        def listing():
            return {item["id"]: item for item in json.loads(run("list"))}

        found = listing()
        check(sorted(found) == ["plain", "shipped-off", "with-action"], f"listed {sorted(found)}")
        check(found.get("plain", {}).get("state") == "running", "plain's unit state was not read")
        check(found.get("with-action", {}).get("state") == "dead", "an escaped unit name was not matched")
        check(found.get("plain", {}).get("comment") == "Starts everywhere", "the comment is missing")
        check(found.get("shipped-off", {}).get("enabled") is False, "a Hidden system entry reads on")

        run("set", "plain", "off")
        override = user / "plain.desktop"
        check(override.exists() and "Hidden=true" in override.read_text(), "off wrote no Hidden=true copy")
        check(listing()["plain"]["enabled"] is False, "plain still reads on")
        run("set", "plain", "on")
        check(not override.exists(), "on left the copy behind")
        check(listing()["plain"]["enabled"] is True, "plain did not come back on")

        run("set", "with-action", "off")
        text = (user / "with-action.desktop").read_text()
        check(text.index("Hidden=true") < text.index("[Desktop Action new]"),
              "Hidden= landed outside [Desktop Entry]")
        run("set", "with-action", "on")

        run("set", "shipped-off", "on")
        check(listing()["shipped-off"]["enabled"] is True, "a Hidden system entry cannot be switched on")

        # A copy the user changed stays when switched back on, just unhidden.
        (user / "plain.desktop").write_text(entry("Plain", "Exec=true --mine"))
        run("set", "plain", "off")
        run("set", "plain", "on")
        mine = user / "plain.desktop"
        check(mine.exists() and "--mine" in mine.read_text() and "Hidden=false" in mine.read_text(),
              "switching on dropped the user's own copy")
        mine.unlink()

        run("add", "my-app")
        added = listing().get("my-app")
        check(added is not None and added["custom"] and added["icon"] == "my-icon", f"add gave {added}")
        run("set", "my-app", "off")
        check((user / "my-app.desktop").exists(), "switching a user's entry off deleted it")
        run("set", "my-app", "on")
        run("remove", "my-app")
        check("my-app" not in listing(), "remove left the entry")
        run("remove", "plain", ok=False)
        run("add", "no-such-app", ok=False)

    if failures:
        print("\n".join(failures))
        sys.exit(1)
    print("autostart: ok")


if __name__ == "__main__":
    main()
