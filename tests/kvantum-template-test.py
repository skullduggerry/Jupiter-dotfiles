#!/usr/bin/env python3
"""The Kvantum theme's template, .config/wallust/templates/Wallust.svg, is what
scripts/kvantum-template.py makes of the KvMojave theme Kvantum installs.

So a hand edit to the template, or a Kvantum update that changed KvMojave,
shows up here: change the script instead, or run it again.

    python3 tests/kvantum-template-test.py        exit 0 on success
"""

from __future__ import annotations

import pathlib
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
SCRIPT = REPO / "scripts/kvantum-template.py"
TEMPLATE = REPO / ".config/wallust/templates/Wallust.svg"
SOURCE = pathlib.Path("/usr/share/Kvantum/KvMojave/KvMojave.svg")


def main() -> int:
    if not SOURCE.exists():
        print("skip: Kvantum's KvMojave theme is not installed")
        return 0
    with tempfile.TemporaryDirectory() as name:
        made = pathlib.Path(name) / "Wallust.svg"
        result = subprocess.run(
            [sys.executable, str(SCRIPT), str(SOURCE), str(made)],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode != 0:
            print(f"FAILED: kvantum-template.py exited {result.returncode}")
            print(result.stderr)
            return 1
        if made.read_text() != TEMPLATE.read_text():
            print(
                "FAILED: templates/Wallust.svg is not what "
                "scripts/kvantum-template.py makes of the installed KvMojave: "
                "run the script again, or make the edit in it"
            )
            return 1
    print("kvantum-template: all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
