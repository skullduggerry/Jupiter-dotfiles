#!/usr/bin/env python3
"""Adding a wallpaper, services/wallpaper-import.sh, with a stand-in zenity.

The picked image is copied into the library and its new path printed; the
same image again changes nothing, another one under a taken name gets a
number, and a cancelled dialog leaves the library alone.

    python3 tests/wallpaper-import-test.py        exit 0 on success
"""

from __future__ import annotations

import os
import pathlib
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
SCRIPT = REPO / ".config/quickshell/services/wallpaper-import.sh"

# The file dialog: prints $PICKED, or is cancelled when there is none.
ZENITY = """#!/bin/sh
[ -n "$PICKED" ] || exit 1
printf '%s\\n' "$PICKED"
"""

failures: list[str] = []


def check(label: str, got: object, want: object) -> None:
    ok = got == want
    print(f"  [{'ok  ' if ok else 'FAIL'}] {label}")
    if not ok:
        failures.append(f"{label}: wanted {want!r}, got {got!r}")


def main() -> int:
    with tempfile.TemporaryDirectory() as name:
        tmp = pathlib.Path(name)
        library = tmp / "Wallpapers" / "Nature"
        bin_dir = tmp / "bin"
        bin_dir.mkdir()
        (bin_dir / "zenity").write_text(ZENITY)
        (bin_dir / "zenity").chmod(0o755)
        first = tmp / "Downloads" / "lake.view.jpg"
        first.parent.mkdir()
        first.write_bytes(b"one lake")
        second = tmp / "lake.view.jpg"
        second.write_bytes(b"another lake")

        def pick(path: pathlib.Path | None) -> tuple[int, str]:
            env = dict(
                os.environ,
                PICKED=str(path or ""),
                PATH=f"{bin_dir}:{os.environ['PATH']}",
            )
            result = subprocess.run(
                [str(SCRIPT), str(library)],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            return result.returncode, result.stdout.strip()

        check("cancelled", pick(None), (1, ""))
        check("nothing made", library.exists(), False)
        landed = library / "lake.view.jpg"
        check("added", pick(first), (0, str(landed)))
        check("copied", landed.read_bytes(), b"one lake")
        check("the same image again", pick(first), (0, str(landed)))
        numbered = library / "lake.view-1.jpg"
        check("another under that name", pick(second), (0, str(numbered)))
        check("kept apart", numbered.read_bytes(), b"another lake")
        check("both there", len(list(library.iterdir())), 2)

    print()
    if failures:
        print(f"FAILED ({len(failures)})")
        for failure in failures:
            print("  -", failure)
        return 1
    print("wallpaper-import: all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
