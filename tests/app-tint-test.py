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

The GTK stylesheets get it in the lines their templates mark glass, and the
GTK theme is named anew (.config/wallust/gtk-theme.sh) only while it is the
one named. GSettings is a keyfile in the made-up home, never the real dconf.
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


def gtk_glass(text):
    return re.findall(r"alpha\(#[0-9A-Fa-f]{6}, ([0-9.]+)\); /\* glass \*/", text)


# A stylesheet made of a template's lines marked glass and a neighbour that
# has an alpha of its own, its expressions filled in.
def gtk_sheet(name):
    lines = (TEMPLATES / name).read_text().splitlines()
    marked = [line for line in lines if "/* glass */" in line]
    other = [line for line in lines if "alpha(" in line and "/* glass */" not in line][:1]
    text = "\n".join(marked + other).replace("{{ window_opacity() }}", "0.60")
    return re.sub(r"\{\{[^}]*\}\}", "#161616", text) + "\n", len(marked)


def gtk_theme(env):
    result = subprocess.run(["gsettings", "get", "org.gnome.desktop.interface", "gtk-theme"],
                            env=env, capture_output=True, text=True)
    return result.stdout.strip()


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
    # The GTK 3 theme has gtk.css's glass (windows) and its own (title bars).
    gtk4, windows = gtk_sheet("gtk.css")
    titlebars, count = gtk_sheet("gtk-3.0.css")
    gtk3 = titlebars + gtk4
    check((windows, count) == (1, 1), f"gtk.css marks {windows} lines as glass and gtk-3.0.css {count}, not 1 each")

    with tempfile.TemporaryDirectory() as tmp:
        root = pathlib.Path(tmp)
        home = root / "home"
        state = root / "state" / "quickshell"
        runtime = root / "runtime"
        kvantum = home / ".config" / "Kvantum" / "Wallust" / "Wallust.svg"
        kvantum.parent.mkdir(parents=True)
        runtime.mkdir()
        kvantum.write_text(svg)
        themes = home / ".local" / "share" / "themes"
        gtk3_theme = themes / "Wallust" / "gtk-3.0" / "gtk.css"
        gtk4_sheet = home / ".config" / "gtk-4.0" / "gtk.css"
        for path, text in ((gtk3_theme, gtk3), (gtk4_sheet, gtk4)):
            path.parent.mkdir(parents=True)
            path.write_text(text)
        env = dict(os.environ, HOME=str(home), XDG_STATE_HOME=str(root / "state"), XDG_RUNTIME_DIR=str(runtime),
                   XDG_CONFIG_HOME=str(root / "config"), GSETTINGS_BACKEND="keyfile")
        settings = subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", "Wallust"],
                                  env=env, capture_output=True, text=True)
        check(settings.returncode == 0, f"gsettings could not name the theme: {settings.stderr.strip()}")

        committed = macros((TEMPLATES / "appearance.jinja").read_text()).get("window_opacity")
        check(rendered(state, env) == committed,
              f"with nothing recorded, appearance.py renders {rendered(state, env)}, not the committed {committed}")

        # Named anew at every run, between its two names.
        for tint, named in (("0.38", "'Wallust-2'"), ("1.00", "'Wallust'"), ("0.25", "'Wallust-2'")):
            result = subprocess.run([str(SCRIPT), tint], env=env, capture_output=True, text=True)
            check(result.returncode == 0, f"{tint}: app-tint.sh failed: {result.stderr.strip()}")
            record = (state / "tint.conf").read_text()
            check(f"\nbackground_opacity {tint}\n" in record, f"{tint}: the record says {record!r}")
            check(not (state / "tint.conf.new").exists(), f"{tint}: the record's temporary file was left behind")
            text = kvantum.read_text()
            check(glass(text) == [tint] * 4, f"{tint}: the glass in Kvantum's SVG is {glass(text)}")
            check(text.splitlines()[4:] == svg.splitlines()[4:], f"{tint}: an element not marked as glass changed")
            check(rendered(state, env) == tint, f"{tint}: appearance.py renders {rendered(state, env)} from the record")
            for path, sheet in ((gtk3_theme, gtk3), (gtk4_sheet, gtk4)):
                text = path.read_text()
                check(gtk_glass(text) == [tint] * len(gtk_glass(sheet)), f"{tint}: the glass in {path.name} is {gtk_glass(text)}")
                check(text.splitlines()[-1] == sheet.splitlines()[-1], f"{tint}: a line of {path.name} not marked as glass changed")
            check(gtk_theme(env) == named, f"{tint}: the GTK theme named is {gtk_theme(env)}, not {named}")
        check((themes / "Wallust-2").resolve() == (themes / "Wallust").resolve(), "Wallust-2 is not a link to the theme")

        # Another theme, named by hand, is left as it is.
        subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", "Adwaita"], env=env)
        subprocess.run([str(SCRIPT), "0.50"], env=env, capture_output=True, text=True)
        check(gtk_theme(env) == "'Adwaita'", f"a theme named by hand became {gtk_theme(env)}")

    for failure in failures:
        print("FAIL:", failure)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
