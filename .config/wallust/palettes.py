#!/usr/bin/env python3
"""Print every theme apply.sh can apply, with its palette, as one JSON array.

    [{"name": "Nord", "custom": false, "palette": {"background": "#2E3440", ...}}, ...]

The built-ins come from `wallust theme list`, the custom ones from colorschemes/.
Each palette is rendered through templates/quickshell.json, the template the
shell takes its colours from, so a preview shows exactly what applying gives.
Everything is written to a temporary directory, and -s keeps wallust away from
the terminals. The shell's wallpaper app runs this for its theme picker.
"""

from __future__ import annotations

import concurrent.futures
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import threading

HERE = pathlib.Path(__file__).resolve().parent
TEMPLATE = HERE / "templates" / "quickshell.json"
SCHEMES = HERE / "colorschemes"


def find_wallust() -> str | None:
    # See apply.sh: the compositor's environment does not include cargo's bin.
    path = (
        os.environ.get("PATH", "")
        + os.pathsep
        + str(pathlib.Path.home() / ".cargo" / "bin")
    )
    return shutil.which("wallust", path=path)


def builtin_names(wallust: str) -> list[str]:
    listing = subprocess.run(
        [wallust, "theme", "list"], capture_output=True, text=True, check=True
    ).stdout
    # "- Nord" per theme; "random" and "list" are commands, and carry a description.
    return [
        line[2:].strip()
        for line in listing.splitlines()
        if line.startswith("- ") and " " not in line[2:].strip()
    ]


class Renderer:
    """One wallust config directory per thread, so parallel renders never share a target."""

    def __init__(self, wallust: str, root: pathlib.Path):
        self.wallust = wallust
        self.root = root
        self.local = threading.local()

    def config_dir(self) -> pathlib.Path:
        if not hasattr(self.local, "dir"):
            path = pathlib.Path(tempfile.mkdtemp(dir=self.root))
            (path / "templates").mkdir()
            shutil.copy(TEMPLATE, path / "templates" / "quickshell.json")
            (path / "wallust.toml").write_text(
                f"[templates]\nquickshell = {{ src = 'quickshell.json', target = '{path / 'out.json'}' }}\n"
            )
            self.local.dir = path
        return self.local.dir

    def render(self, args: list[str]) -> dict | None:
        path = self.config_dir()
        out = path / "out.json"
        out.unlink(missing_ok=True)
        result = subprocess.run(
            [self.wallust, "-d", str(path), "-s", "-q", *args],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode != 0 or not out.exists():
            return None
        return json.loads(out.read_text())


def main() -> int:
    wallust = find_wallust()
    if wallust is None:
        print("wallust is not installed", file=sys.stderr)
        return 1

    jobs = [
        (scheme.stem, True, ["cs", str(scheme)])
        for scheme in sorted(SCHEMES.glob("*.json"))
    ]
    jobs += [(name, False, ["theme", name]) for name in builtin_names(wallust)]

    with tempfile.TemporaryDirectory() as root:
        renderer = Renderer(wallust, pathlib.Path(root))
        with concurrent.futures.ThreadPoolExecutor(
            max_workers=os.cpu_count() or 4
        ) as pool:
            palettes = list(
                pool.map(lambda job: renderer.render(job[2]), jobs)
            )

    themes = [
        {"name": name, "custom": custom, "palette": palette}
        for (name, custom, _), palette in zip(jobs, palettes, strict=True)
        if palette is not None
    ]
    json.dump(themes, sys.stdout)
    return 0


if __name__ == "__main__":
    sys.exit(main())
