#!/usr/bin/env python3
"""Print templates/appearance.jinja for the Settings app's current choices.

    appearance.py STATE_FILE

STATE_FILE is the shell's $XDG_STATE_HOME/quickshell/appearance.json. When the
shell runs apply.sh it also passes APPEARANCE_ACCENT and APPEARANCE_FONT, which
win: a choice made a moment ago may not be in the file yet. The glass the apps
get is what the shell last recorded in tint.conf beside it
(.config/quickshell/services/app-tint.sh). apply.sh renders the app templates
from a copy of templates/ with this in place of the committed appearance.jinja,
which holds the defaults; so do a missing file and an empty value.
"""

import json
import os
import re
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
# The shell's tint for a dark theme until it records one.
DEFAULT_TINT = 0.6


def tint(path):
    try:
        with open(path) as file:
            for line in file:
                key, _, value = line.partition(" ")
                if key == "background_opacity":
                    return min(1.0, max(0.0, float(value)))
    except (OSError, ValueError):
        pass
    return DEFAULT_TINT


def main(path):
    try:
        with open(path) as file:
            settings = json.load(file)
    except (OSError, ValueError):
        settings = {}
    if not isinstance(settings, dict):
        settings = {}
    accent = os.environ.get("APPEARANCE_ACCENT", settings.get("accent"))
    accent = SLOTS.get(
        accent if isinstance(accent, str) else "", SLOTS["blue"]
    )
    font = os.environ.get("APPEARANCE_FONT", settings.get("font"))
    # A family name goes into kdeglobals' comma-separated font lines and
    # qt6ct's quoted ones, and into the template as a string, never as Jinja.
    font = re.sub(
        r'[,"\x00-\x1f\x7f]', " ", font if isinstance(font, str) else ""
    )
    font = json.dumps(font.strip() or DEFAULT_FONT, ensure_ascii=False)
    print("{%- macro accent_color() -%}{{ " + accent + " }}{%- endmacro -%}")
    print("{%- macro font_family() -%}{{ " + font + " }}{%- endmacro -%}")
    # Kvantum's window and dialog backgrounds, which KvMojave drew at 93% and
    # 92%, as the shell writes the tint (app-tint.sh), two decimals.
    glass = tint(os.path.join(os.path.dirname(path), "tint.conf"))
    print(
        "{%- macro window_opacity() -%}" + f"{glass:.2f}" + "{%- endmacro -%}"
    )


if __name__ == "__main__":
    main(sys.argv[1])
