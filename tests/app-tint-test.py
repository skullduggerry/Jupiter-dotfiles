#!/usr/bin/env python3
"""The apps' glass: services/app-tint.sh against a made-up home, and
appearance.py reading back what it recorded.

The script records the tint for kitty and writes it into the elements of
Kvantum's SVG that the template marks as glass (the windows' and dialogs'
backgrounds), leaving every other line alone. The SVG here is made of the
template's own lines, its expressions filled in. appearance.py renders the
same value from the record when a theme is applied, so a theme render and the
script never disagree. The runtime folder has no kitty sockets in it, so no
kitty is contacted.
"""
import os
import pathlib
import re
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
SCRIPT = REPO / ".config" / "quickshell" / "services" / "app-tint.sh"
APPEARANCE = REPO / ".config" / "wallust" / "appearance.py"
TEMPLATES = REPO / ".config" / "wallust" / "templates"

failures = []


def check(condition, message):
    if not condition:
        failures.append(message)


def macros(text):
    found = {}
    for line in text.splitlines():
        match = re.fullmatch(r"\{%- macro (\w+)\(\) -%\}(.*)\{%- endmacro -%\}", line)
        if match:
            found[match.group(1)] = match.group(2)
    return found


def glass(text):
    return re.findall(r'class="tint"[^>]*?opacity:([0-9.]+)', text)


def rendered(state, env):
    result = subprocess.run([sys.executable, str(APPEARANCE), str(state / "appearance.json")],
                            env=env, capture_output=True, text=True)
    check(result.returncode == 0, f"appearance.py failed: {result.stderr.strip()}")
    return macros(result.stdout).get("window_opacity")


def main():
    template = (TEMPLATES / "Wallust.svg").read_text().splitlines()
    marked = [line for line in template if 'class="tint"' in line]
    check(len(marked) == 4, f"the template marks {len(marked)} elements as glass, not 4 (2 windows, 2 dialogs)")
    # Glass and two unmarked neighbours with an opacity of their own.
    others = [line for line in template if "opacity:" in line and 'class="tint"' not in line][:2]
    svg = "\n".join(marked + others)
    svg = svg.replace("{{ window_opacity() }}", "0.60")
    svg = re.sub(r"\{\{[^}]*\}\}", "#161616", svg) + "\n"

    with tempfile.TemporaryDirectory() as tmp:
        root = pathlib.Path(tmp)
        home = root / "home"
        state = root / "state" / "quickshell"
        runtime = root / "runtime"
        kvantum = home / ".config" / "Kvantum" / "Wallust" / "Wallust.svg"
        kvantum.parent.mkdir(parents=True)
        runtime.mkdir()
        kvantum.write_text(svg)
        env = dict(os.environ, HOME=str(home), XDG_STATE_HOME=str(root / "state"), XDG_RUNTIME_DIR=str(runtime))

        committed = macros((TEMPLATES / "appearance.jinja").read_text()).get("window_opacity")
        check(rendered(state, env) == committed,
              f"with nothing recorded, appearance.py renders {rendered(state, env)}, not the committed {committed}")

        for tint in ("0.38", "1.00", "0.25"):
            result = subprocess.run([str(SCRIPT), tint], env=env, capture_output=True, text=True)
            check(result.returncode == 0, f"{tint}: app-tint.sh failed: {result.stderr.strip()}")
            record = (state / "tint.conf").read_text()
            check(f"\nbackground_opacity {tint}\n" in record, f"{tint}: the record says {record!r}")
            check(not (state / "tint.conf.new").exists(), f"{tint}: the record's temporary file was left behind")
            text = kvantum.read_text()
            check(glass(text) == [tint] * 4, f"{tint}: the glass in Kvantum's SVG is {glass(text)}")
            check(text.splitlines()[4:] == svg.splitlines()[4:], f"{tint}: an element not marked as glass changed")
            check(rendered(state, env) == tint, f"{tint}: appearance.py renders {rendered(state, env)} from the record")

    for failure in failures:
        print("FAIL:", failure)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
