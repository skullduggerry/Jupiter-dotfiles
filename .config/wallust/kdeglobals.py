#!/usr/bin/env python3
"""Merge the kdeglobals wallust rendered into ~/.config/kdeglobals.

    kdeglobals.py RENDERED TARGET

Key by key: KDE apps keep settings of their own in kdeglobals (the file
dialog's, for one), and rendering over the whole file threw them away at every
login. Only the keys the template sets are replaced. Comments are dropped, as
KConfig drops them whenever an app writes the file.
"""

import os
import re
import stat
import sys
import tempfile

GROUP = re.compile(r"^\s*\[(.+)\]\s*$")
# The key with its [locale] and [$flags]: Name[de] is not Name.
ENTRY = re.compile(r"^\s*([^=]+?)\s*=(.*)$")


def read_groups(path):
    """[(group, [lines])] in file order, comments left out; lines before the
    first header go under None."""
    groups: list[tuple[str | None, list[str]]] = [(None, [])]
    try:
        with open(path) as file:
            lines = file.read().splitlines()
    except FileNotFoundError:
        return groups
    for line in lines:
        if line.lstrip().startswith("#"):
            continue
        match = GROUP.match(line)
        if match:
            groups.append((match.group(1), []))
        else:
            groups[-1][1].append(line)
    return groups


def entries(lines):
    found = {}
    for line in lines:
        match = ENTRY.match(line)
        if match:
            found[match.group(1)] = match.group(2)
    return found


def merge(rendered_path, target_path):
    rendered = [
        (name, entries(lines))
        for name, lines in read_groups(rendered_path)
        if name
    ]
    target = read_groups(target_path)

    for name, values in rendered:
        lines = next((lines for group, lines in target if group == name), None)
        if lines is None:
            lines = []
            target.append((name, lines))
        for key, value in values.items():
            for index, line in enumerate(lines):
                match = ENTRY.match(line)
                if match and match.group(1) == key:
                    lines[index] = f"{key}={value}"
                    break
            else:
                end = len(lines)
                while end > 0 and lines[end - 1].strip() == "":
                    end -= 1
                lines.insert(end, f"{key}={value}")

    out: list[str] = []
    for name, lines in target:
        if name is not None:
            if out and out[-1].strip() != "":
                out.append("")
            out.append(f"[{name}]")
        out.extend(lines)
    while out and out[-1].strip() == "":
        out.pop()

    # Written beside the file and renamed over it, as KConfig does, so an app
    # never reads half of it; through a symlink, if it is one.
    target_path = os.path.realpath(target_path)
    directory = os.path.dirname(target_path)
    os.makedirs(directory, exist_ok=True)
    try:
        mode = stat.S_IMODE(os.stat(target_path).st_mode)
    except FileNotFoundError:
        mode = 0o644
    handle, temporary = tempfile.mkstemp(dir=directory, prefix=".kdeglobals.")
    with os.fdopen(handle, "w") as file:
        file.write("\n".join(out) + "\n")
    os.chmod(temporary, mode)
    os.replace(temporary, target_path)


if __name__ == "__main__":
    merge(sys.argv[1], sys.argv[2])
