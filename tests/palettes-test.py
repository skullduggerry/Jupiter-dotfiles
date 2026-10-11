#!/usr/bin/env python3
"""The Settings app's theme catalogue, .config/wallust/palettes.py, rendered by
the real wallust (with -s, its cache in a temporary folder).

The themes saved in colorschemes/ come first, marked custom and coloured as
saved; wallust's built-ins follow; every palette has the colours the shell
reads; and a theme wallust cannot render is left out rather than failing
the catalogue.

    python3 tests/palettes-test.py        exit 0 on success
"""

from __future__ import annotations

import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
WALLUST_DIR = REPO / ".config/wallust"
SCRIPT = WALLUST_DIR / "palettes.py"
KEYS = {
    "background",
    "foreground",
    "cursor",
    *(f"color{n}" for n in range(16)),
}

failures: list[str] = []


def check(label: str, got: object, want: object) -> None:
    ok = got == want
    print(f"  [{'ok  ' if ok else 'FAIL'}] {label}")
    if not ok:
        failures.append(f"{label}: wanted {want!r}, got {got!r}")


def catalogue(env: dict[str, str]) -> list[dict]:
    result = subprocess.run(
        [sys.executable, str(SCRIPT)],
        env=env,
        capture_output=True,
        text=True,
        timeout=120,
        check=False,
    )
    check("palettes.py exits 0", result.returncode, 0)
    return json.loads(result.stdout or "[]")


def main() -> int:
    path = (
        os.environ.get("PATH", "")
        + os.pathsep
        + str(pathlib.Path.home() / ".cargo/bin")
    )
    wallust = shutil.which("wallust", path=path)
    if wallust is None:
        print("skip: wallust is not installed")
        return 0

    with tempfile.TemporaryDirectory() as name:
        tmp = pathlib.Path(name)
        env = dict(os.environ, XDG_CACHE_HOME=str(tmp / "cache"))
        themes = catalogue(env)
        saved = sorted(
            scheme.stem for scheme in WALLUST_DIR.glob("colorschemes/*.json")
        )
        custom = [theme["name"] for theme in themes if theme["custom"]]
        check(
            "the saved schemes, first",
            [t["name"] for t in themes[: len(saved)]],
            saved,
        )
        check("and only they are custom", custom, saved)
        check("the built-ins after them", len(themes) > len(saved) + 10, True)
        check(
            "every palette has what the shell reads",
            [t["name"] for t in themes if set(t["palette"]) != KEYS],
            [],
        )
        check(
            "as colours",
            [
                t["name"]
                for t in themes
                if not all(
                    re.fullmatch(r"#[0-9A-Fa-f]{6}", value)
                    for value in t["palette"].values()
                )
            ],
            [],
        )
        if saved:
            scheme = json.loads(
                (WALLUST_DIR / "colorschemes" / f"{saved[0]}.json").read_text()
            )
            palette = themes[0]["palette"]
            check(
                f"{saved[0]} as saved",
                (palette["background"].lower(), palette["color1"].lower()),
                (scheme["background"].lower(), scheme["color"][1].lower()),
            )

        # A wallust that fails one theme: the rest still come.
        bin_dir = tmp / "bin"
        bin_dir.mkdir()
        failing = themes[-1]["name"]
        (bin_dir / "wallust").write_text(
            f'#!/bin/sh\ncase " $* " in *" theme {failing} "*) exit 1 ;; esac\nexec {wallust} "$@"\n'
        )
        (bin_dir / "wallust").chmod(0o755)
        env["PATH"] = f"{bin_dir}:{os.environ['PATH']}"
        rest = catalogue(env)
        check(
            "a theme that does not render is left out",
            [t["name"] for t in rest],
            [t["name"] for t in themes if t["name"] != failing],
        )

    print()
    if failures:
        print(f"FAILED ({len(failures)})")
        for failure in failures:
            print("  -", failure)
        return 1
    print("palettes: all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
