#!/usr/bin/env python3
"""Move `pragma` lines back to the top of a QML file after qmlformat.

qmlformat sorts pragmas below the imports. Quickshell's documentation says to
put `pragma Singleton` at the top of the file, and its own priority order puts
Quickshell's guidance above Qt's, so the pragma is hoisted back. The shell does
load either way -- this is consistency with the documented form, not a fix.

    scripts/hoist-pragmas.py FILE...
"""
from __future__ import annotations

import pathlib
import sys


def hoist(path: pathlib.Path) -> bool:
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    pragmas = [l for l in lines if l.startswith("pragma ")]
    if not pragmas or all(lines[i].startswith("pragma ") for i in range(len(pragmas))):
        return False
    rest = [l for l in lines if not l.startswith("pragma ")]
    while rest and rest[0].strip() == "":
        rest.pop(0)
    path.write_text("".join(pragmas) + "\n" + "".join(rest), encoding="utf-8")
    return True


if __name__ == "__main__":
    changed = sum(hoist(pathlib.Path(p)) for p in sys.argv[1:])
    print(f"hoisted pragmas in {changed} file(s)")
