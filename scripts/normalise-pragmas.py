#!/usr/bin/env python3
"""Read QML on stdin, print it with pragma lines hoisted to the top.

Used by scripts/check.sh to compare a file against qmlformat's output without
the pragma placement counting as a difference: qmlformat sorts pragmas below
the imports, the project keeps them on line 1 per Quickshell's documentation.
"""
import sys

lines = sys.stdin.read().splitlines(keepends=True)
pragmas = [l for l in lines if l.startswith("pragma ")]
rest = [l for l in lines if not l.startswith("pragma ")]
while rest and rest[0].strip() == "":
    rest.pop(0)
sys.stdout.write("".join(pragmas) + ("\n" if pragmas else "") + "".join(rest))
