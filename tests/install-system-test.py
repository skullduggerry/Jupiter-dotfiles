#!/usr/bin/env python3
"""scripts/install-system.sh, into a stand-in root.

It installs every udev rule and pacman hook in etc/ and the script the hook
runs, where the hook looks for it, then runs that script once over the
desktop entries already there; it leaves udev alone outside the real root
(a stand-in udevadm on PATH would note a call), and running it twice is the
same as once.

    python3 tests/install-system-test.py        exit 0 on success
"""

from __future__ import annotations

import os
import pathlib
import re
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
SCRIPT = REPO / "scripts/install-system.sh"

failures: list[str] = []


def check(label: str, got: object, want: object) -> None:
    ok = got == want
    print(f"  [{'ok  ' if ok else 'FAIL'}] {label}")
    if not ok:
        failures.append(f"{label}: wanted {want!r}, got {got!r}")


def main() -> int:
    with tempfile.TemporaryDirectory() as name:
        tmp = pathlib.Path(name)
        root = tmp / "root"
        apps = root / "usr/share/applications"
        apps.mkdir(parents=True)
        (apps / "cloud.desktop").write_text(
            "[Desktop Entry]\nName=Cloud\nExec=cloud\n\n[org.example.Group]\nKey=value\n"
        )
        bin_dir = tmp / "bin"
        bin_dir.mkdir()
        udevadm = bin_dir / "udevadm"
        udevadm.write_text(f'#!/bin/sh\necho "$*" >> "{tmp}/udevadm"\n')
        udevadm.chmod(0o755)

        def install() -> subprocess.CompletedProcess[str]:
            return subprocess.run(
                ["bash", str(SCRIPT), str(root)],
                env=dict(os.environ, PATH=f"{bin_dir}:{os.environ['PATH']}"),
                capture_output=True,
                text=True,
                check=False,
            )

        result = install()
        check("exits 0", (result.returncode, result.stderr), (0, ""))
        for source in [
            *REPO.glob("etc/udev/rules.d/*.rules"),
            *REPO.glob("etc/pacman.d/hooks/*.hook"),
        ]:
            target = root / source.relative_to(REPO)
            check(
                f"{target.relative_to(root)}",
                target.read_bytes() if target.exists() else None,
                source.read_bytes(),
            )
            check(
                f"{target.name} readable, not writable",
                oct(target.stat().st_mode & 0o777)
                if target.exists()
                else None,
                "0o644",
            )
        helper = root / "usr/local/lib/jupiter/uwsm-desktop-entries.py"
        check(
            "helper executable",
            helper.exists() and os.access(helper, os.X_OK),
            True,
        )
        hook = (
            REPO / "etc/pacman.d/hooks/uwsm-desktop-entries.hook"
        ).read_text()
        execs = re.findall(r"^Exec = (\S+)", hook, re.MULTILINE)
        check(
            "the hook runs it where it is installed",
            execs,
            ["/usr/local/lib/jupiter/uwsm-desktop-entries.py"],
        )
        copy = root / "usr/local/share/applications/cloud.desktop"
        check("entries already there got their copy", copy.exists(), True)
        check("udev left alone", (tmp / "udevadm").exists(), False)

        before = sorted(
            str(path.relative_to(root)) for path in root.rglob("*")
        )
        check("twice is once", install().returncode, 0)
        check(
            "same files",
            sorted(str(path.relative_to(root)) for path in root.rglob("*")),
            before,
        )

    if failures:
        print("\n".join(["", "FAILED:", *failures]))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
