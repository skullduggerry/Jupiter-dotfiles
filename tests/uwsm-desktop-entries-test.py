#!/usr/bin/env python3
"""scripts/uwsm-desktop-entries.py, in a stand-in root.

Nextcloud's entry, as nextcloud-client 35 installs it, gets a copy in
/usr/local/share/applications without its [org.freedesktop.CloudProviders]
group and Implements= key, and the rest as it was; an entry uwsm takes as it
is gets none. The targets come on stdin as pacman's NeedsTargets passes them,
or are every entry when there are none. A copy goes once its entry is gone or
no longer needs one, and one this did not write is never touched. Where uwsm
is installed, its own validation refuses the entry and takes the copy.

    python3 tests/uwsm-desktop-entries-test.py        exit 0 on success
"""

from __future__ import annotations

import contextlib
import io
import os
import pathlib
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
SCRIPT = REPO / "scripts/uwsm-desktop-entries.py"
UWSM = pathlib.Path("/usr/share/uwsm/modules")

NEXTCLOUD = """[Desktop Entry]
Categories=Utility;X-SuSE-SyncUtility;
Type=Application
Exec=nextcloud %u
Name=Nextcloud Desktop
Icon=Nextcloud
SingleMainWindow=true
Actions=Quit;

# Translations
Name[de]=Nextcloud Desktop
Implements=org.freedesktop.CloudProviders

[org.freedesktop.CloudProviders]
BusName=com.nextcloudgmbh.Nextcloud
ObjectPath=/com/nextcloudgmbh/Nextcloud

[Desktop Action Quit]
Exec=nextcloud --quit
Name=Quit Nextcloud
"""
CLEANED = """[Desktop Entry]
Categories=Utility;X-SuSE-SyncUtility;
Type=Application
Exec=nextcloud %u
Name=Nextcloud Desktop
Icon=Nextcloud
SingleMainWindow=true
Actions=Quit;

# Translations
Name[de]=Nextcloud Desktop

[Desktop Action Quit]
Exec=nextcloud --quit
Name=Quit Nextcloud
"""
KITTY = """[Desktop Entry]
Type=Application
Name=kitty
Exec=kitty

[X-Extra]
Key=value
"""

failures: list[str] = []


def check(label: str, got: object, want: object) -> None:
    ok = got == want
    print(f"  [{'ok  ' if ok else 'FAIL'}] {label}")
    if not ok:
        failures.append(f"{label}: wanted {want!r}, got {got!r}")


def run(root: pathlib.Path, stdin: str | None) -> str:
    result = subprocess.run(
        [sys.executable, str(SCRIPT)],
        env=dict(os.environ, ROOT=str(root)),
        input=stdin if stdin is not None else "",
        capture_output=True,
        text=True,
        check=False,
    )
    check(
        "exits 0",
        (result.returncode, result.stderr.startswith("Traceback")),
        (0, False),
    )
    return result.stdout + result.stderr


def uwsm_takes(path: pathlib.Path) -> bool:
    sys.path.insert(0, str(UWSM))
    from uwsm.main import check_entry_basic  # type: ignore[import-not-found]
    from xdg.DesktopEntry import DesktopEntry  # type: ignore[import-untyped]

    try:
        with (
            contextlib.redirect_stdout(io.StringIO()),
            contextlib.redirect_stderr(io.StringIO()),
        ):
            check_entry_basic(DesktopEntry(str(path)))
    except RuntimeError:
        return False
    return True


def main() -> int:
    with tempfile.TemporaryDirectory() as name:
        root = pathlib.Path(name)
        apps = root / "usr/share/applications"
        copies = root / "usr/local/share/applications"
        apps.mkdir(parents=True)
        nextcloud = apps / "com.nextcloud.desktopclient.nextcloud.desktop"
        nextcloud.write_text(NEXTCLOUD)
        (apps / "kitty.desktop").write_text(KITTY)
        copy = copies / nextcloud.name

        targets = f"usr/share/applications/{nextcloud.name}\nusr/share/applications/kitty.desktop\nusr/share/icons/x.png\n"
        run(root, targets)
        lines = copy.read_text().splitlines(keepends=True)
        check(
            "first line marks the copy",
            lines[0].startswith(
                "# Written by Jupiter-dotfiles' uwsm-desktop-entries.py: "
            ),
            True,
        )
        check(
            "copy is the entry without the group and key",
            "".join(lines[1:]),
            CLEANED,
        )
        check(
            "copy is world readable", oct(copy.stat().st_mode & 0o777), "0o644"
        )
        check(
            "kitty, with an X- group, needs none",
            sorted(path.name for path in copies.iterdir()),
            [nextcloud.name],
        )

        if (UWSM / "uwsm/main.py").exists():
            check("uwsm refuses the entry", uwsm_takes(nextcloud), False)
            check("uwsm takes the copy", uwsm_takes(copy), True)

        # An upgrade that drops the group: the copy goes.
        nextcloud.write_text(CLEANED)
        run(root, f"usr/share/applications/{nextcloud.name}\n")
        check(
            "an entry that no longer needs one loses its copy",
            copy.exists(),
            False,
        )

        # Every entry when nothing is named, which also clears copies of
        # entries that are gone.
        nextcloud.write_text(NEXTCLOUD)
        run(root, None)
        check("with no targets, every entry", copy.exists(), True)
        nextcloud.unlink()
        run(root, None)
        check("a removed package's copy goes", copy.exists(), False)

        # An administrator's own copy stays.
        nextcloud.write_text(NEXTCLOUD)
        copy.write_text("[Desktop Entry]\nName=Mine\n")
        output = run(root, f"usr/share/applications/{nextcloud.name}\n")
        check(
            "someone else's copy is left",
            copy.read_text(),
            "[Desktop Entry]\nName=Mine\n",
        )
        check("and it says so", "not written by this" in output, True)
        nextcloud.unlink()
        run(root, f"usr/share/applications/{nextcloud.name}\n")
        check("nor removed", copy.exists(), True)

    if failures:
        print("\n".join(["", "FAILED:", *failures]))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
