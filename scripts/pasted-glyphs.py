#!/usr/bin/env python3
"""List the QML files with a pasted Nerd Font glyph, and fail if there is one.

Tooling has silently emptied pasted private-use codepoints before -- the
calendar's month chevrons, and very nearly the bluetooth and wifi icons --
leaving `text: ""` and no error anywhere. Written as "\\u{F0141}" escapes they
are plain ASCII and cannot be lost, so scripts/check.sh accepts no other form.
"""
import pathlib
import re
import sys

PRIVATE_USE = re.compile("[-\U000f0000-\U000ffffd]")

found = [path for root in (".config/quickshell", "etc/greetd")
         for path in sorted(pathlib.Path(root).rglob("*.qml"))
         if PRIVATE_USE.search(path.read_text(encoding="utf-8"))]
for path in found:
    print(path)
sys.exit(1 if found else 0)
