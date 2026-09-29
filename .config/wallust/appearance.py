#!/usr/bin/env python3
"""Print templates/appearance.jinja for the Settings app's current choices.

    appearance.py STATE_FILE

STATE_FILE is the shell's $XDG_STATE_HOME/quickshell/appearance.json. When the
shell runs apply.sh it also passes APPEARANCE_ACCENT and APPEARANCE_FONT, which
win: a choice made a moment ago may not be in the file yet. apply.sh renders
the app templates from a copy of templates/ with this in place of the
committed appearance.jinja, which holds the defaults; so do a missing file and
an empty value.
"""
import json
import os
import sys

# The shell's accents (style/Colors.qml accentNames) as palette slots; orange
# is halfway from red to yellow there as well.
SLOTS = {
    "blue": "color4",
    "purple": "color5",
    "cyan": "color6",
    "green": "color2",
    "orange": "color1 | blend(color3)",
    "red": "color1",
}
DEFAULT_FONT = "JetBrainsMono Nerd Font"


def main(path):
    try:
        with open(path) as file:
            settings = json.load(file)
    except (OSError, ValueError):
        settings = {}
    accent = SLOTS.get(os.environ.get("APPEARANCE_ACCENT", settings.get("accent")), SLOTS["blue"])
    font = os.environ.get("APPEARANCE_FONT", settings.get("font")) or DEFAULT_FONT
    # A family name goes into kdeglobals' comma-separated font lines as it is.
    font = font.replace(",", " ")
    print("{%- macro accent_color() -%}{{ " + accent + " }}{%- endmacro -%}")
    print("{%- macro font_family() -%}" + font + "{%- endmacro -%}")


if __name__ == "__main__":
    main(sys.argv[1])
