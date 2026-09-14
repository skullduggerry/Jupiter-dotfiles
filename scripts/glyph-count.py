#!/usr/bin/env python3
"""Count Nerd Font private-use codepoints across the repo's QML.

Tooling has silently emptied these before -- the calendar's month chevrons, and
very nearly the bluetooth and wifi icons -- leaving `text: ""` and no error
anywhere. scripts/check.sh compares the working tree against HEAD so a net loss
fails the build.

Counted repo-wide rather than per file: moving a glyph from one file to another
is routine (extracting a panel out of a widget does it), and only a net loss
means codepoints were actually destroyed.

    scripts/glyph-count.py            count the working tree
    scripts/glyph-count.py --head     count HEAD
"""
from __future__ import annotations

import pathlib
import subprocess
import sys

PRIVATE_USE = ((0xE000, 0xF8FF), (0xF0000, 0xFFFFD))


def count(text: str) -> int:
    return sum(1 for c in text
               if any(low <= ord(c) <= high for low, high in PRIVATE_USE))


def from_head() -> int:
    names = subprocess.run(["git", "ls-tree", "-r", "--name-only", "HEAD"],
                           capture_output=True, text=True).stdout.split()
    total = 0
    for name in names:
        if not name.endswith(".qml"):
            continue
        blob = subprocess.run(["git", "show", f"HEAD:{name}"],
                              capture_output=True).stdout
        try:
            total += count(blob.decode("utf-8"))
        except UnicodeDecodeError:
            continue
    return total


def from_tree() -> int:
    total = 0
    for root in ("config/quickshell", ".config/quickshell", "etc/greetd"):
        base = pathlib.Path(root)
        if not base.is_dir():
            continue
        for path in base.rglob("*.qml"):
            try:
                total += count(path.read_text(encoding="utf-8"))
            except (OSError, UnicodeDecodeError):
                continue
    return total


if __name__ == "__main__":
    print(from_head() if "--head" in sys.argv else from_tree())
