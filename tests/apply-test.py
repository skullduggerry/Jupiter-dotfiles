#!/usr/bin/env python3
"""Applying a theme, .config/wallust/apply.sh, against a stand-in wallust and
gsettings in a made-up home.

A theme renders every template from a copy of templates/ whose
appearance.jinja holds the Settings app's choices, merges kdeglobals, tells
the portal dark or light, and is recorded with its scope; --shell-only
renders the shell's palette alone, and without -s nothing; no argument
applies the recorded theme again the same way, or the default; a theme
saved in colorschemes/ goes through `cs`; --from generates a scheme first
and applies it by the image's name.

    python3 tests/apply-test.py        exit 0 on success
"""

from __future__ import annotations

import os
import pathlib
import re
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
WALLUST = REPO / ".config/wallust"
SCRIPT = WALLUST / "apply.sh"

# Records its arguments, and what a render leaves for apply.sh to read next.
STAND_IN_WALLUST = """#!/bin/sh
printf '%s\\n' "$*" >>"$CALLS"
for arg; do
    if [ "$previous" = -d ]; then
        [ -L "$arg/templates/appearance.jinja" ] || cat "$arg/templates/appearance.jinja" >"$CALLS.appearance"
    fi
    previous=$arg
done
mkdir -p "$HOME/.cache/wallust"
printf '[Colors:Window]\\nBackgroundNormal=1,2,3\\n' >"$HOME/.cache/wallust/kdeglobals"
printf 'prefer-dark\\n' >"$HOME/.cache/wallust/color-scheme"
"""
GSETTINGS = """#!/bin/sh
printf '%s\\n' "gsettings $*" >>"$CALLS"
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
            ("wallust", STAND_IN_WALLUST),
            ("gsettings", GSETTINGS),
        ):
            (bin_dir / tool).write_text(text)
            (bin_dir / tool).chmod(0o755)
        calls = home / "calls"
        state = home / ".local/state/wallust/theme"
        env = {
            key: value
            for key, value in os.environ.items()
            if not key.startswith(("XDG_", "WALLUST_", "APPEARANCE_"))
        } | {
            "HOME": str(home),
            "PATH": f"{bin_dir}:{os.environ['PATH']}",
            "CALLS": str(calls),
            "APPEARANCE_ACCENT": "green",
        }

        def apply(*args: str) -> list[str]:
            calls.write_text("")
            result = subprocess.run(
                [str(SCRIPT), *args],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            check(
                f"apply.sh {' '.join(args) or '(bare)'} exits 0",
                result.returncode,
                0,
            )
            # The copy of the config folder is a new temporary one each time.
            return [
                re.sub(r"-d \S+", "-d COPY", line)
                for line in calls.read_text().splitlines()
            ]

        check(
            "no theme yet: the default, to everything",
            apply(),
            [
                "-q -d COPY theme Oxocarbon-Dark",
                "gsettings set org.gnome.desktop.interface color-scheme prefer-dark",
            ],
        )
        check(
            "the app templates get the accent picked",
            "{{ color2 }}" in pathlib.Path(f"{calls}.appearance").read_text(),
            True,
        )
        check(
            "kdeglobals merged into the config",
            "BackgroundNormal=1,2,3"
            in (home / ".config/kdeglobals").read_text(),
            True,
        )
        check("recorded", state.read_text(), "Oxocarbon-Dark\nall\n")

        check(
            "--shell-only: the palette alone, terminals untouched",
            apply("--shell-only", "Nord"),
            [f"-q -C {WALLUST}/shell.toml -s theme Nord"],
        )
        check(
            "recorded as shell-only", state.read_text(), "Nord\nshell-only\n"
        )
        check(
            "again, the same way",
            apply(),
            [f"-q -C {WALLUST}/shell.toml -s theme Nord"],
        )

        scheme = next(WALLUST.glob("colorschemes/*.json")).stem
        check(
            "a saved scheme goes through cs",
            apply(scheme)[0],
            f"-q -d COPY cs {scheme}.json",
        )

        check(
            "--from: a scheme from the image, applied by its name",
            apply("--from", "/pictures/Lake.View.jpg")[:2],
            [
                "-q -s -T run --save-scheme /pictures/Lake.View.jpg",
                "-q -d COPY theme Lake",
            ],
        )
        check("recorded by that name", state.read_text(), "Lake\nall\n")

    print()
    if failures:
        print(f"FAILED ({len(failures)})")
        for failure in failures:
            print("  -", failure)
        return 1
    print("apply: all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
