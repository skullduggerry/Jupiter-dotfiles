#!/usr/bin/env python3
"""The shortcuts overlay's keymap helper, against xkbcommon's own layouts.

keymap.py has to say what every key types in every layout (a dead key as its
accent, no control characters), tell an ISO layout from an ANSI one by the key
left of Z, and compile with Hyprland's options and pass on
resolve_binds_by_sym, which it asks a stand-in hyprctl on PATH for here; with
no Hyprland to answer it keeps xkbcommon's defaults.
"""
import json
import os
import pathlib
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
HELPER = REPO / ".config" / "quickshell" / "services" / "keymap.py"

HYPRCTL = """#!/bin/sh
case "$3" in
    input:kb_options) echo '{"option": "input:kb_options", "str": "ctrl:swapcaps", "set": true }' ;;
    input:resolve_binds_by_sym) echo '{"option": "input:resolve_binds_by_sym", "bool": true, "set": true }' ;;
    *) echo '{"option": "'"$3"'", "str": "[[EMPTY]]", "set": false }' ;;
esac
"""

failures = []


def check(condition, message):
    if not condition:
        failures.append(message)


def main():
    with tempfile.TemporaryDirectory() as tmp:
        root = pathlib.Path(tmp)
        bin_dir = root / "bin"
        bin_dir.mkdir()
        hyprctl = bin_dir / "hyprctl"
        hyprctl.write_text(HYPRCTL)
        hyprctl.chmod(0o755)

        def run(layouts, variants, path, ok=True):
            result = subprocess.run([sys.executable, str(HELPER), layouts, variants],
                                    env=dict(os.environ, PATH=path), capture_output=True, text=True)
            check((result.returncode == 0) == ok, f"{layouts}: exit {result.returncode} {result.stderr.strip()}")
            return json.loads(result.stdout) if result.returncode == 0 else None

        # No hyprctl at all: xkbcommon's defaults.
        plain = run("us,de", ",", str(root / "nowhere")) or {"layouts": [{"keys": {}}, {"keys": {}}]}
        us, de = (layout["keys"] for layout in plain["layouts"])
        check(plain.get("resolveBySym") is False, f"resolveBySym {plain.get('resolveBySym')!r} without Hyprland")
        check([layout.get("iso") for layout in plain["layouts"]] == [False, True], "us should be ANSI, de ISO")

        def key(keys, name):
            return keys.get(name, {"code": None, "syms": [None, None], "text": [None, None]})

        check(key(us, "AD01") == {"code": 24, "syms": ["q", "Q"], "text": ["q", "Q"]}, f"us AD01 {key(us, 'AD01')}")
        check(key(us, "AD06")["text"] == ["y", "Y"] and key(de, "AD06")["text"] == ["z", "Z"], "de swaps Y and Z")
        check(key(de, "AE11")["text"] == ["ß", "?"], f"de AE11 {key(de, 'AE11')['text']}")
        check(key(de, "TLDE")["text"] == ["^", "°"], f"a dead circumflex shows as ^: {key(de, 'TLDE')['text']}")
        check(key(de, "AE12")["text"] == ["´", "`"], f"dead acute and grave: {key(de, 'AE12')['text']}")
        check(key(de, "RALT")["syms"][0] == "ISO_Level3_Shift", "de's right Alt is AltGr")
        check(key(us, "RTRN") == {"code": 36, "syms": ["Return", ""], "text": ["", ""]},
              f"Return types no text: {key(us, 'RTRN')}")
        check(key(us, "SPCE")["text"] == ["", ""], "space has no text to show")
        check(key(us, "PRSC")["syms"][0] == "Print", "Print is on PRSC")

        # Hyprland's options go into the keymap, and its binds setting comes along.
        swapped = run("us", "", f"{bin_dir}:/usr/bin")
        if swapped is not None:
            keys = swapped["layouts"][0]["keys"]
            check(key(keys, "CAPS")["syms"][0] == "Control_L" and key(keys, "LCTL")["syms"][0] == "Caps_Lock",
                  "kb_options ctrl:swapcaps did not reach the keymap")
            check(swapped["resolveBySym"] is True, "resolve_binds_by_sym was not passed on")

        run("no-such-layout", "", str(root / "nowhere"), ok=False)

    if failures:
        print("\n".join(failures))
        sys.exit(1)
    print("keymap: ok")


if __name__ == "__main__":
    main()
