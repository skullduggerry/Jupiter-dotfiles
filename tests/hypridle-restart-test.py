#!/usr/bin/env python3
"""Restarting hypridle on a new config, services/hypridle-restart.sh.

Only the hypridle of this Hyprland goes, the one whose environment has its
instance signature: another session's keeps running. Here two `sleep`s with
signatures of their own stand in for them, a stand-in pgrep names only
those, and stand-ins for hypridle and uwsm-app record how they were started
(in a scope of its own under uwsm).

    python3 tests/hypridle-restart-test.py        exit 0 on success
"""

from __future__ import annotations

import os
import pathlib
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
SCRIPT = REPO / ".config/quickshell/services/hypridle-restart.sh"

PGREP = """#!/bin/sh
cat "$IDLERS"
"""
RECORD = """#!/bin/sh
printf '%s\\n' "${0##*/} $*" >>"$STARTED"
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
        bin_dir = tmp / "bin"
        bin_dir.mkdir()
        for tool, text in (
            ("pgrep", PGREP),
            ("hypridle", RECORD),
            ("uwsm-app", RECORD),
        ):
            (bin_dir / tool).write_text(text)
            (bin_dir / tool).chmod(0o755)
        idlers = tmp / "idlers"
        started = tmp / "started"

        def idler(signature: str) -> subprocess.Popen[bytes]:
            env = dict(os.environ, HYPRLAND_INSTANCE_SIGNATURE=signature)
            return subprocess.Popen(["sleep", "60"], env=env)

        def restart(**extra: str) -> list[str]:
            started.write_text("")
            env = dict(
                os.environ,
                HYPRLAND_INSTANCE_SIGNATURE="this-session",
                IDLERS=str(idlers),
                STARTED=str(started),
                PATH=f"{bin_dir}:{os.environ['PATH']}",
            )
            env.pop("UWSM_FINALIZE_VARNAMES", None)
            env.update(extra)
            subprocess.run(
                [str(SCRIPT), "/state/hypridle.conf"],
                env=env,
                check=False,
                timeout=10,
            )
            return started.read_text().splitlines()

        ours, theirs = idler("this-session"), idler("another-session")
        try:
            idlers.write_text(f"{ours.pid}\n{theirs.pid}\n")
            check(
                "started again on the new config",
                restart(),
                ["hypridle -c /state/hypridle.conf"],
            )
            check("this session's stopped", ours.wait(timeout=5), -15)
            check("another session's kept", theirs.poll(), None)
            check(
                "under uwsm, in a scope of its own",
                restart(UWSM_FINALIZE_VARNAMES="X"),
                ["uwsm-app -s b -- hypridle -c /state/hypridle.conf"],
            )
        finally:
            for process in (ours, theirs):
                process.kill()
                process.wait()

    print()
    if failures:
        print(f"FAILED ({len(failures)})")
        for failure in failures:
            print("  -", failure)
        return 1
    print("hypridle-restart: all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
