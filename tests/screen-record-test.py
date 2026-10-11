#!/usr/bin/env python3
"""Screen Record's helper, services/screen-record.sh, with stand-ins for
xdg-user-dir and setpriv, so nothing records.

It prints the new file's path first, in Recordings/ of the videos folder,
or of ~/Videos where xdg-user-dirs has none (it names $HOME then), and hands
wf-recorder to setpriv so the recording ends with the shell.

    python3 tests/screen-record-test.py        exit 0 on success
"""

from __future__ import annotations

import os
import pathlib
import re
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
SCRIPT = REPO / ".config/quickshell/services/screen-record.sh"

XDG_USER_DIR = """#!/bin/sh
printf '%s\\n' "$VIDEOS"
"""
SETPRIV = """#!/bin/sh
printf '%s\\n' "$*" >"$HOME/setpriv"
"""

failures: list[str] = []


def check(label: str, got: object, want: object) -> None:
    ok = got == want
    print(f"  [{'ok  ' if ok else 'FAIL'}] {label}")
    if not ok:
        failures.append(f"{label}: wanted {want!r}, got {got!r}")


def main() -> int:
    with tempfile.TemporaryDirectory() as name:
        home = pathlib.Path(name)
        bin_dir = home / "bin"
        bin_dir.mkdir()
        for tool, text in (
            ("xdg-user-dir", XDG_USER_DIR),
            ("setpriv", SETPRIV),
        ):
            (bin_dir / tool).write_text(text)
            (bin_dir / tool).chmod(0o755)

        def record(videos: str) -> pathlib.Path:
            env = dict(
                os.environ,
                HOME=str(home),
                VIDEOS=videos,
                PATH=f"{bin_dir}:{os.environ['PATH']}",
            )
            result = subprocess.run(
                [str(SCRIPT), "DP-2"],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            check(f"records with videos at {videos!r}", result.returncode, 0)
            return pathlib.Path(result.stdout.strip())

        file = record(str(home / "Films"))
        check("in Recordings/", file.parent, home / "Films/Recordings")
        check("which exists", file.parent.is_dir(), True)
        check(
            "named by the time",
            re.fullmatch(r"\d{4}-\d\d-\d\d_\d\d-\d\d-\d\d\.mp4", file.name)
            is not None,
            True,
        )
        check(
            "wf-recorder ends with the shell",
            (home / "setpriv").read_text().strip(),
            f"--pdeathsig INT wf-recorder -o DP-2 -f {file}",
        )
        check(
            "no videos folder of its own",
            record(str(home) + "/").parent,
            home / "Videos/Recordings",
        )
        check("none at all", record("").parent, home / "Videos/Recordings")

    print()
    if failures:
        print(f"FAILED ({len(failures)})")
        for failure in failures:
            print("  -", failure)
        return 1
    print("screen-record: all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
