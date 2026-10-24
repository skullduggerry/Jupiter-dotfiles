#!/usr/bin/env python3
"""Desktop entries uwsm will start, for etc/pacman.d/hooks/uwsm-desktop-entries.hook.

    uwsm-desktop-entries.py [usr/share/applications/NAME.desktop ...]

uwsm 0.27 starts an app by its entry only once pyxdg finds nothing wrong with
it, and pyxdg knows neither the spec's Implements= key nor groups other than
[Desktop Entry], [Desktop Action …] and [X-…]. Nextcloud's entry has both, for
the CloudProviders spec ([org.freedesktop.CloudProviders], read by GNOME
Files), so `uwsm app`, and with it the shell's launcher and Hyprland's binds,
refused to start Nextcloud at all.

For each entry named (pacman passes the changed ones on stdin; with neither,
every one in usr/share/applications), this writes a copy without them to
/usr/local/share/applications, which comes first in XDG_DATA_DIRS, so it
stands in for the package's file and that file stays as pacman installed it.
A copy this wrote is removed once its entry no longer needs one, or is gone.
ROOT replaces / for the tests.
"""

import os
import re
import sys
from pathlib import Path

ROOT = Path(os.environ.get("ROOT", "/"))
SOURCE = Path("usr/share/applications")
COPIES = ROOT / "usr/local/share/applications"
MARK = "# Written by Jupiter-dotfiles' uwsm-desktop-entries.py: "
GROUP = re.compile(r"^\[(.+)\]\s*$")
IMPLEMENTS = re.compile(r"^Implements\s*=")


def known(group: str) -> bool:
    """A group pyxdg's validation takes."""
    return (
        group == "Desktop Entry"
        or re.fullmatch(r"Desktop Action [A-Za-z0-9-]+", group) is not None
        or (group.startswith("X-") and group.isascii())
    )


def cleaned(text: str) -> str | None:
    """The entry without what pyxdg refuses, or None if it refuses nothing."""
    kept = []
    group = ""
    dropped = False
    for line in text.splitlines(keepends=True):
        header = GROUP.match(line)
        if header:
            group = header.group(1)
        if not known(group) and group != "":
            dropped = True
            continue
        if group == "Desktop Entry" and IMPLEMENTS.match(line):
            dropped = True
            continue
        kept.append(line)
    return "".join(kept) if dropped else None


def ours(copy: Path) -> bool:
    try:
        with copy.open() as file:
            return file.readline().startswith(MARK)
    except OSError:
        return False


def update(name: str) -> None:
    source = ROOT / SOURCE / name
    copy = COPIES / name
    try:
        text = source.read_text()
    except OSError:
        text = None
    fixed = cleaned(text) if text is not None else None
    if fixed is None:
        if ours(copy):
            copy.unlink()
            print(f"removed {copy}")
        return
    # Never over one an administrator put there.
    if copy.exists() and not ours(copy):
        print(f"left {copy}: not written by this", file=sys.stderr)
        return
    COPIES.mkdir(parents=True, exist_ok=True)
    temporary = copy.with_name(f".{name}.part")
    temporary.write_text(
        f"{MARK}/{SOURCE / name} without what uwsm refuses\n{fixed}"
    )
    temporary.chmod(0o644)
    temporary.replace(copy)
    print(f"wrote {copy}")


def main() -> None:
    targets = sys.argv[1:] or (
        [] if sys.stdin.isatty() else sys.stdin.read().split()
    )
    if targets:
        names = [
            Path(target).name
            for target in targets
            if Path(target).parent == SOURCE
        ]
    else:
        # Every entry there is, and every copy left from one that is gone.
        present = [path.name for path in (ROOT / SOURCE).glob("*.desktop")]
        stale = [path.name for path in COPIES.glob("*.desktop") if ours(path)]
        names = sorted(set(present + stale))
    for name in names:
        if name.endswith(".desktop"):
            update(name)


if __name__ == "__main__":
    main()
