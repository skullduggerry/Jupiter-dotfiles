#!/usr/bin/env python3
"""The shelf's file work, services/shelf.sh, against a stand-in clipboard.

Pasting keeps text, an image or the files a file manager copied as new files,
numbered rather than written over, with a hidden name left visible, and never
a password manager's copy; a note is named after its first line; copying
puts text and images back as themselves and anything else as its file. Every
file is written under a hidden .part name first, and none of those is left.

    python3 tests/shelf-test.py        exit 0 on success
"""

from __future__ import annotations

import os
import pathlib
import re
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
SCRIPT = REPO / ".config/quickshell/services/shelf.sh"
STAMP = r"\d{4}-\d\d-\d\d_\d\d-\d\d-\d\d"
PNG = bytes.fromhex(
    "89504e470d0a1a0a0000000d4948445200000001000000010806000000"
    "1f15c4890000000d49444154789c6360000002000154a24f5d0000000049454e44ae426082"
)

# A clipboard made of files: $CLIP/types lists what it holds, and $CLIP/<type>
# (slashes as underscores) holds each. wl-copy keeps what it is given.
WL_PASTE = """#!/bin/sh
[ -f "$CLIP/types" ] || exit 1
[ "$1" = --list-types ] && exec cat "$CLIP/types"
for last; do :; done
exec cat "$CLIP/$(printf %s "$last" | tr / _)"
"""
WL_COPY = """#!/bin/sh
printf '%s\\n' "$*" >"$CLIP/copied-as"
cat >"$CLIP/copied"
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
        clip = tmp / "clip"
        shelf = tmp / "Shelf"
        bin_dir = tmp / "bin"
        bin_dir.mkdir()
        for tool, text in (("wl-paste", WL_PASTE), ("wl-copy", WL_COPY)):
            (bin_dir / tool).write_text(text)
            (bin_dir / tool).chmod(0o755)
        env = dict(
            os.environ, CLIP=str(clip), PATH=f"{bin_dir}:{os.environ['PATH']}"
        )

        def clipboard(**held: str | bytes) -> None:
            if clip.exists():
                for old in clip.iterdir():
                    old.unlink()
            clip.mkdir(exist_ok=True)
            (clip / "types").write_text("\n".join(held) + "\n")
            for kind, data in held.items():
                target = clip / kind.replace("/", "_")
                if isinstance(data, bytes):
                    target.write_bytes(data)
                else:
                    target.write_text(data)

        def shelf_sh(*args: str) -> tuple[int, list[str]]:
            result = subprocess.run(
                [str(SCRIPT), *args],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            return result.returncode, result.stdout.splitlines()

        # Text, as a new file named by the time.
        clipboard(**{"text/plain;charset=utf-8": "", "text": "hello shelf"})
        code, names = shelf_sh("paste", str(shelf))
        check("text pastes", code, 0)
        check(
            "named by the time",
            bool(names)
            and re.fullmatch(STAMP + r"\.txt", names[0]) is not None,
            True,
        )
        if names:
            check("its text", (shelf / names[0]).read_text(), "hello shelf")

        # An image, as itself.
        clipboard(**{"image/png": PNG})
        code, names = shelf_sh("paste", str(shelf))
        check(
            "an image pastes",
            (code, [n.endswith(".png") for n in names]),
            (0, [True]),
        )

        # Files a file manager copied: the files, copied, under their names.
        source = tmp / "My notes"
        source.mkdir()
        (source / "plan.txt").write_text("the plan")
        (source / ".hidden").write_text("not hidden on the shelf")
        uris = "\r\n".join(
            [
                "file://" + str(source / "plan.txt").replace(" ", "%20"),
                "file://" + str(source / ".hidden").replace(" ", "%20"),
                "https://example.org/not-a-file",
            ]
        )
        clipboard(**{"text/uri-list": uris, "text": uris})
        code, names = shelf_sh("paste", str(shelf))
        check("copied files paste", (code, names), (0, ["plan.txt", "hidden"]))
        check("as they were", (shelf / "plan.txt").read_text(), "the plan")
        code, names = shelf_sh("paste", str(shelf))
        check("a taken name is numbered", names, ["plan-1.txt", "hidden-1"])

        # A password manager's copy stays off a synced folder.
        clipboard(**{"text": "hunter2", "x-kde-passwordManagerHint": "secret"})
        before = sorted(shelf.iterdir())
        code, names = shelf_sh("paste", str(shelf))
        check("a password is refused", (code, names), (3, []))
        check("and nothing written", sorted(shelf.iterdir()), before)

        # Nothing to paste.
        (clip / "types").unlink()
        check("an empty clipboard", shelf_sh("paste", str(shelf))[0], 1)
        clipboard(**{"application/x-other": "?"})
        check("nothing it can keep", shelf_sh("paste", str(shelf))[0], 1)

        # Notes, named after their first line, without what a name cannot hold.
        code, names = shelf_sh(
            "note", str(shelf), "  ../Groceries: milk/eggs?\nand bread"
        )
        check("a note", (code, names), (0, ["Groceries milkeggs.md"]))
        check(
            "keeps its text",
            (shelf / "Groceries milkeggs.md").read_text(),
            "  ../Groceries: milk/eggs?\nand bread\n",
        )
        check("a blank note", shelf_sh("note", str(shelf), " \n\t")[0], 1)

        # Copying back: text as text, an image as an image, else the file.
        image = next(shelf.glob("*.png"))
        for label, file, kind in (
            ("text copies as text", shelf / "plan.txt", ""),
            ("an image copies as an image", image, "--type image/png"),
        ):
            shelf_sh("copy", str(file))
            copied = (clip / "copied-as").read_text().strip()
            check(
                label,
                (copied, (clip / "copied").read_bytes()),
                (kind, file.read_bytes()),
            )
        other = shelf / "form.pdf"
        other.write_bytes(b"%PDF-1.4\n%%EOF\n")
        shelf_sh("copy", str(other))
        check(
            "anything else copies as its file",
            (
                (clip / "copied-as").read_text().strip(),
                (clip / "copied").read_text().strip(),
            ),
            ("--type text/uri-list", other.as_uri()),
        )

        check("no .part file is left", list(shelf.glob(".*.part")), [])
        check("an unknown command", shelf_sh("move")[0], 2)

    print()
    if failures:
        print(f"FAILED ({len(failures)})")
        for failure in failures:
            print("  -", failure)
        return 1
    print("shelf: all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
