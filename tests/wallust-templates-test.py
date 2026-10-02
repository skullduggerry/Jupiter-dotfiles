#!/usr/bin/env python3
"""Every wallust template renders, for a dark theme and a light one, and
kdeglobals.py merges without losing what KDE apps wrote.

wallust only warns when a template fails to render and still exits 0, so a
broken template would otherwise go unnoticed until the colours were wrong.
Rendered into a temporary directory with -s, so no terminal is touched. The
GTK stylesheets go through GTK's own parsers (PyGObject, which blueman brings),
which skip what they cannot read with no more than a warning in the app.
"""
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import tomllib
import xml.etree.ElementTree as ET

REPO = pathlib.Path(__file__).resolve().parent.parent
WALLUST_DIR = REPO / ".config" / "wallust"
sys.path.insert(0, str(WALLUST_DIR))
import kdeglobals  # noqa: E402

failures = []


def check(condition, message):
    if not condition:
        failures.append(message)


GTK_PARSE = """
import sys, gi
gi.require_version("Gtk", sys.argv[1])
from gi.repository import Gtk
errors = []
provider = Gtk.CssProvider()
provider.connect("parsing-error", lambda p, section, error: errors.append(error.message))
text = sys.stdin.read()
try:
    if hasattr(provider, "load_from_string"):
        provider.load_from_string(text)
    else:
        provider.load_from_data(text.encode())
except Exception:
    pass
print("\\n".join(errors))
"""


# What GTK's parser reports for a stylesheet; None without PyGObject or that
# GTK. No display is needed to parse.
def gtk_errors(version, text):
    env = {k: v for k, v in os.environ.items() if k not in ("WAYLAND_DISPLAY", "DISPLAY")}
    result = subprocess.run([sys.executable, "-c", GTK_PARSE, version], input=text, env=env,
                            capture_output=True, text=True)
    if result.returncode != 0:
        return None
    return [line for line in result.stdout.splitlines() if line]


def find_wallust():
    path = os.environ.get("PATH", "") + os.pathsep + str(pathlib.Path.home() / ".cargo" / "bin")
    return shutil.which("wallust", path=path)


def render(wallust, theme, root):
    config = root / theme
    shutil.copytree(WALLUST_DIR / "templates", config / "templates")
    templates = tomllib.loads((WALLUST_DIR / "wallust.toml").read_text())["templates"]
    lines = ["[templates]"]
    for name, entry in templates.items():
        lines.append(f"{name} = {{ src = '{entry['src']}', target = '{config / 'out' / name}' }}")
    (config / "wallust.toml").write_text("\n".join(lines) + "\n")
    result = subprocess.run([wallust, "-d", str(config), "-q", "-s", "theme", theme],
                            capture_output=True, text=True)
    check(result.returncode == 0 and result.stderr.strip() == "",
          f"{theme}: wallust reported {result.stderr.strip() or result.returncode}")
    return {name: (config / "out" / name) for name in templates}


def test_templates(wallust):
    with tempfile.TemporaryDirectory() as tmp:
        root = pathlib.Path(tmp)
        for theme, scheme, icons in (("Oxocarbon-Dark", "dark", "breeze-dark"),
                                     ("Catppuccin-Latte", "light", "breeze")):
            out = render(wallust, theme, root)
            for name, path in out.items():
                check(path.exists(), f"{theme}: {name} was not rendered")
                if path.exists():
                    text = path.read_text()
                    check("{{" not in text and "{%" not in text, f"{theme}: {name} kept template syntax")
            if out["kvantum-svg"].exists():
                try:
                    ET.parse(out["kvantum-svg"])
                except ET.ParseError as error:
                    failures.append(f"{theme}: the Kvantum SVG is not valid XML: {error}")
                # Windows and dialogs at appearance.jinja's default glass.
                glass = re.findall(r'class="tint"[^>]*?opacity:([0-9.]+)', out["kvantum-svg"].read_text())
                check(glass == ["0.60"] * 4, f"{theme}: the Kvantum SVG's glass is {glass}, not four at 0.60")
            if out["color-scheme"].exists():
                check(out["color-scheme"].read_text().strip() == f"prefer-{scheme}",
                      f"{theme}: color-scheme is not prefer-{scheme}")
            if out["kdeglobals"].exists():
                groups = dict((name, kdeglobals.entries(lines))
                              for name, lines in kdeglobals.read_groups(out["kdeglobals"]) if name)
                check(groups.get("Icons", {}).get("Theme") == icons, f"{theme}: icon theme is not {icons}")
                check(groups.get("UiSettings", {}).get("ColorScheme") == "Wallust",
                      f"{theme}: kdeglobals does not name the Wallust colour scheme")
                for value in groups.get("Colors:View", {}).values():
                    parts = value.split(",")
                    check(len(parts) == 3 and all(p.isdigit() and int(p) <= 255 for p in parts),
                          f"{theme}: [Colors:View] has a value that is not R,G,B: {value}")
            if out["qt6ct"].exists():
                check(f"icon_theme={icons}\n" in out["qt6ct"].read_text(), f"{theme}: qt6ct's icon theme is not {icons}")
            variant = "adw-gtk3" if scheme == "light" else "adw-gtk3-dark"
            for name, version in (("gtk3", "3.0"), ("gtk4-theme", "4.0")):
                if out[name].exists():
                    imports = re.findall(r'@import url\("file:///usr/share/themes/([^/]+)/gtk-(\d\.\d)/gtk\.css"\);',
                                         out[name].read_text())
                    check(imports == [(variant, version)], f"{theme}: {name} imports {imports}, not {variant}'s gtk-{version}")
            # Windows' glass at appearance.jinja's default, and GTK 3's title bars'.
            for name, count in (("gtk3", 2), ("gtk4", 1)):
                if out[name].exists():
                    glass = re.findall(r"alpha\(#[0-9A-Fa-f]{6}, ([0-9.]+)\); /\* glass \*/", out[name].read_text())
                    check(glass == ["0.60"] * count, f"{theme}: {name}'s glass is {glass}, not {count} at 0.60")
            # The repo's own CSS, not adw-gtk3's, which may not be installed here.
            for name, version in (("gtk3", "3.0"), ("gtk4", "4.0")):
                if out[name].exists():
                    errors = gtk_errors(version, re.sub(r"(?m)^@import .*$", "", out[name].read_text()))
                    check(not errors, f"{theme}: GTK {version} cannot read {name}: {errors}")


def test_merge():
    with tempfile.TemporaryDirectory() as tmp:
        root = pathlib.Path(tmp)
        rendered = root / "rendered"
        target = root / "kdeglobals"
        rendered.write_text("[KDE]\nwidgetStyle=kvantum\n\n[Icons]\nTheme=breeze\n\n[Colors:View]\nBackgroundNormal=1,2,3\n")
        target.write_text("# Generated by wallust\n[KDE]\nwidgetStyle=kvantum\nSingleClick=true\n\n"
                          "[KFileDialog Settings]\nShow hidden files=true\n\n[Colors:View]\nBackgroundNormal=9,9,9\n")
        kdeglobals.merge(rendered, target)
        groups = dict((name, kdeglobals.entries(lines)) for name, lines in kdeglobals.read_groups(target) if name)
        check(groups["KDE"] == {"widgetStyle": "kvantum", "SingleClick": "true"},
              f"[KDE] after the merge: {groups['KDE']}")
        check(groups.get("KFileDialog Settings") == {"Show hidden files": "true"}, "an app's own group was lost")
        check(groups["Colors:View"] == {"BackgroundNormal": "1,2,3"}, "a colour was not replaced")
        check(groups.get("Icons") == {"Theme": "breeze"}, "a group the file lacked was not added")
        check("#" not in target.read_text(), "a comment survived the merge")
        merged = target.read_text()
        kdeglobals.merge(rendered, target)
        check(target.read_text() == merged, "merging again changed the file")


def main():
    wallust = find_wallust()
    if wallust is None:
        print("skip: wallust is not installed")
        return 0
    test_templates(wallust)
    test_merge()
    for failure in failures:
        print("FAIL:", failure)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
