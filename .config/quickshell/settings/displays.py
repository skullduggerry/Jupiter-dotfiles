#!/usr/bin/env python3
"""Monitor rules for the Settings app's Displays page.

    displays.py apply RULES      apply them now, through `hyprctl eval`
    displays.py save RULES       keep them, merged by output
    displays.py forget OUTPUT    drop what was kept for one output

RULES is a JSON list of hl.monitor tables: {"output": "desc:…", "mode":
"1920x1080@143.98", "position": "0x0", "scale": 1, "transform": 0, "vrr": 1,
"disabled": false}. Kept rules live in $XDG_STATE_HOME/quickshell/monitors.json
and, as the Lua that .config/hypr/modules/monitors.lua loads after its own
rules, in monitors.lua beside it: Hyprland takes the newest rule matching a
monitor, so they win there, as they do when applied at runtime, where
hl.monitor adds a rule after the config's. scripts/install-greeter.sh bakes the
Lua one into the login screen's layout.
"""

import json
import math
import os
import subprocess
import sys
import tempfile

FIELDS: dict[str, type | tuple[type, ...]] = {
    "output": str,
    "mode": str,
    "position": str,
    "scale": (int, float),
    "transform": int,
    "vrr": int,
    "disabled": bool,
}


LUA_ESCAPES = {
    **{chr(code): f"\\{code:03d}" for code in (*range(32), 127)},
    "\\": "\\\\",
    '"': '\\"',
}


def state_dir():
    state = os.environ.get("XDG_STATE_HOME") or os.path.expanduser(
        "~/.local/state"
    )
    return os.path.join(state, "quickshell")


def checked(rules):
    if not isinstance(rules, list):
        raise SystemExit("displays: rules must be a list")
    for rule in rules:
        if (
            not isinstance(rule, dict)
            or not isinstance(rule.get("output"), str)
            or not rule["output"]
        ):
            raise SystemExit(f"displays: a rule needs an output: {rule!r}")
        for key, value in rule.items():
            kind = FIELDS.get(key)
            if kind is None:
                raise SystemExit(f"displays: unknown field {key!r}")
            # bool is an int in Python; only disabled takes one. JSON's NaN
            # and Infinity are floats that Lua has no literal for.
            if (
                not isinstance(value, kind)
                or (isinstance(value, bool) and kind is not bool)
                or (isinstance(value, float) and not math.isfinite(value))
            ):
                raise SystemExit(f"displays: {key} cannot be {value!r}")
    return rules


def lua_value(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return (
            str(int(value))
            if float(value).is_integer()
            else repr(float(value))
        )
    # A control character, a line break above all, would end the string.
    return '"' + "".join(LUA_ESCAPES.get(char, char) for char in value) + '"'


def lua_table(rule):
    return (
        "{ "
        + ", ".join(
            f"{key} = {lua_value(rule[key])}" for key in FIELDS if key in rule
        )
        + " }"
    )


def apply(rules):
    code = "\n".join(f"hl.monitor({lua_table(rule)})" for rule in rules)
    result = subprocess.run(
        ["hyprctl", "eval", code], capture_output=True, text=True, check=False
    )
    out = (result.stdout + result.stderr).strip()
    if result.returncode != 0 or out != "ok":
        raise SystemExit(f"displays: {out or 'hyprctl failed'}")


def kept():
    path = os.path.join(state_dir(), "monitors.json")
    try:
        with open(path, encoding="utf-8") as file:
            return checked(json.load(file))
    except FileNotFoundError:
        return []
    except (ValueError, SystemExit) as error:
        # Kept aside rather than overwritten: the rules are someone's work.
        os.replace(path, path + ".broken")
        print(
            f"displays: monitors.json unreadable ({error}), "
            "moved to monitors.json.broken",
            file=sys.stderr,
        )
        return []


def write(name, text):
    directory = state_dir()
    os.makedirs(directory, exist_ok=True)
    handle, temporary = tempfile.mkstemp(dir=directory, prefix=".monitors-")
    with os.fdopen(handle, "w", encoding="utf-8") as file:
        file.write(text)
    os.chmod(temporary, 0o644)
    os.replace(temporary, os.path.join(directory, name))


def store(rules):
    write("monitors.json", json.dumps(rules, indent=2) + "\n")
    lines = [
        "-- Written by the shell's Settings app (Displays); edits here are lost on",
        "-- its next save. .config/hypr/modules/monitors.lua applies these after",
        "-- its own rules, so they win.",
        "return {",
    ]
    lines += [f"\t{lua_table(rule)}," for rule in rules]
    lines.append("}")
    write("monitors.lua", "\n".join(lines) + "\n")


def save(rules):
    merged = {rule["output"]: rule for rule in kept()}
    for rule in rules:
        merged[rule["output"]] = rule
    store(list(merged.values()))


def forget(output):
    store([rule for rule in kept() if rule["output"] != output])


def main(argv):
    if len(argv) == 3 and argv[1] in ("apply", "save"):
        try:
            rules = checked(json.loads(argv[2]))
        except ValueError as error:
            raise SystemExit(
                f"displays: rules are not JSON: {error}"
            ) from None
        (apply if argv[1] == "apply" else save)(rules)
    elif len(argv) == 3 and argv[1] == "forget":
        forget(argv[2])
    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main(sys.argv)
