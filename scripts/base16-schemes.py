#!/usr/bin/env python3
"""Write .config/wallust/base16/THEME.json for each theme NixOS pre-builds:
the theme's palette in base16's slots, as templates/base16.json maps them.

    scripts/base16-schemes.py [-o DIR] [THEME ...]

Jupiter-installer's flake makes a home-manager specialisation of each file,
with it as Stylix's scheme, and apply.sh switches to the theme's when it
applies the theme, so the apps Stylix themes follow it. Without THEME, the
themes already there are rendered again (after a change to the template or
to wallust); a THEME named is added. A theme is found as apply.sh finds it:
colorschemes/THEME.json, else wallust's built-in. Rendered with -s and a
cache of its own in a temporary folder, so no terminal or theme is touched.
"""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
from typing import Any

REPO = pathlib.Path(__file__).resolve().parent.parent
WALLUST_DIR = REPO / ".config/wallust"
OUT = WALLUST_DIR / "base16"


def find_wallust() -> str | None:
    # Where cargo installs it, as apply.sh adds to PATH.
    path = (
        os.environ.get("PATH", "")
        + os.pathsep
        + str(pathlib.Path.home() / ".cargo/bin")
    )
    return shutil.which("wallust", path=path)


def render(wallust: str, theme: str, work: pathlib.Path) -> dict[str, Any]:
    """The theme's base16 scheme, named."""
    config = work / theme
    (config / "templates").mkdir(parents=True)
    # base16.json imports palette.jinja, which imports appearance.jinja: the
    # committed defaults, as no slot depends on the Settings app's choices.
    for template in (WALLUST_DIR / "templates").iterdir():
        (config / "templates" / template.name).symlink_to(template)
    (config / "colorschemes").symlink_to(WALLUST_DIR / "colorschemes")
    out = config / "base16.json"
    (config / "wallust.toml").write_text(
        f"[templates]\nbase16 = {{ src = 'base16.json', target = '{out}' }}\n"
    )
    if (WALLUST_DIR / "colorschemes" / f"{theme}.json").is_file():
        args = ["cs", f"{theme}.json"]
    else:
        args = ["theme", theme]
    result = subprocess.run(
        [wallust, "-d", str(config), "-q", "-s", *args],
        env=dict(os.environ, XDG_CACHE_HOME=str(work / "cache")),
        capture_output=True,
        text=True,
        check=False,
    )
    # A theme wallust does not know fails; a template error is only a
    # warning, and leaves no file.
    if result.returncode != 0 or not out.exists():
        raise ValueError(result.stderr.strip() or f"wallust wrote no {out}")
    scheme = json.loads(out.read_text())
    palette = {
        slot: colour.lower() for slot, colour in scheme["palette"].items()
    }
    return {
        "system": scheme["system"],
        "name": theme,
        "author": "Jupiter-dotfiles, from wallust's palette",
        "variant": scheme["variant"],
        "palette": palette,
    }


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Render base16 schemes for NixOS's Stylix."
    )
    parser.add_argument("-o", "--out", type=pathlib.Path, default=OUT)
    parser.add_argument("themes", nargs="*")
    args = parser.parse_args(argv)
    wallust = find_wallust()
    if wallust is None:
        print("wallust is not installed", file=sys.stderr)
        return 1
    themes = args.themes or sorted(
        path.stem for path in args.out.glob("*.json")
    )
    args.out.mkdir(parents=True, exist_ok=True)
    failed = []
    with tempfile.TemporaryDirectory() as work:
        for theme in themes:
            try:
                scheme = render(wallust, theme, pathlib.Path(work))
            except ValueError as error:
                print(f"{theme}: {error}", file=sys.stderr)
                failed.append(theme)
                continue
            (args.out / f"{theme}.json").write_text(
                json.dumps(scheme, indent=2, ensure_ascii=False) + "\n"
            )
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
