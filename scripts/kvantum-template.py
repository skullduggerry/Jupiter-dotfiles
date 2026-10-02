#!/usr/bin/env python3
"""Write .config/wallust/templates/Wallust.svg: Kvantum's KvMojave SVG with
its colours put on the wallust palette.

    scripts/kvantum-template.py [SOURCE [TEMPLATE]]

SOURCE defaults to the KvMojave.svg the kvantum package installs, which the
Wallust Kvantum theme has always been drawn from. Rerun it after a kvantum
update changes that file; see "The Kvantum theme follows the palette" in
.github/THEMING.md.

Neutral greys become mix(background, foreground, t), with t measured against
KvMojave's own window (#302f2e) and text (#ffffff), so the window is exactly
the palette's background and a light theme mirrors the dark one. Blues become
the accent (color4) shifted towards white or black by as much as the original
was lighter or darker than KvMojave's accent (#286adc). White is the text
colour, except for check marks drawn on the accent, which take the background.
Black stays black: it is only ever a shadow or an outline at low opacity.
Windows and dialogs, which KvMojave drew a little translucent, take the
shell's glass instead (appearance.jinja's window_opacity()).

Arrows are line chevrons, as the shell draws them (Lucide's, muted, the text
colour under the pointer): KvMojave's filled arrowheads stood out beside line
icons. KvMojave has no plain arrow-* or menuitem-*-normal elements, and
Kvantum draws a missing element from its built-in theme, in its own grey, so
those are added as the toolbar's.
"""
import colorsys
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
src = sys.argv[1] if len(sys.argv) > 1 else "/usr/share/Kvantum/KvMojave/KvMojave.svg"
dst = sys.argv[2] if len(sys.argv) > 2 else REPO / ".config" / "wallust" / "templates" / "Wallust.svg"
text = open(src).read()

REF_BG = (0x30, 0x2F, 0x2E)
REF_ACCENT = (0x28, 0x6A, 0xDC)
ON_ACCENT = ("checkbox-checked", "checkbox-tristate", "radio-checked",
             "menu-checkbox-checked", "menu-radio-checked", "item-checkbox-tristate",
             "menuitem")
# Selected and pressed rows: an accent tint under ordinary text, so it reads
# the same whether a view draws selected text as Text or as HighlightedText.
SELECTION = {"itemview-toggled": "selection(0.4)", "itemview-pressed": "selection(0.5)"}
# Menu and menu bar highlights likewise, under the menu's ordinary text.
TINTED = ("menuitem", "menubaritem")
AUTO_ID = re.compile(r"^(path|g|rect|use|circle|ellipse|stop|linearGradient|radialGradient|svg|defs)\d")
COLOUR = re.compile(r"#[0-9a-fA-F]{6}\b|#[0-9a-fA-F]{3}\b")
# The window backgrounds' opacity and the translucent end of the dialogs'
# gradients. class="tint" marks them for the shell's services/app-tint.sh,
# which writes a new tint into the rendered file.
WINDOWS = ("window-normal", "window-normal-inactive")
DIALOGS = ("dialog-normal", "dialog-normal-inactive")
OPACITY = re.compile(r"\b((?:stop-)?opacity):[0-9.]+")
# A chevron's colour by the state its element is drawn for: Colors.text.muted,
# the text under the pointer or pressed, and the disabled text of the
# kvconfig.
CHEVRON = {"normal": "shade(0.7)", "focused": "foreground", "pressed": "foreground", "disabled": "shade(0.45)"}
CHEVRON_STYLE = "fill:none;stroke:{{ %s }};stroke-width:2.4;stroke-linecap:round;stroke-linejoin:round"
# An arrowhead: an invisible 24 unit square, which is what Kvantum scales to
# the indicator's size, then the filled head pointing up in it. The other
# directions are <use>s turning these.
ARROWHEAD = re.compile(
    r'(<g id="(?P<id>(?:tarrow|flat-arrow)-up-\w+|menuitem-right-focused)"[^>]*>\s*'
    r'<path style="opacity:0;[^"]*" d="m -607\.493,(?P<x>[0-9.]+) h 24 v 24 h -24 z" transform="rotate\(-90\)"/>\s*)'
    r'<path style="[^"]*" d="[^"]*"/>')
# The combo boxes' up-and-down arrow: its upper half, mirrored by a <use>.
COMBO_ARROW = re.compile(
    r'(<g id="carrow-(?P<state>normal|focused)"[^>]*>\s*<path style="opacity:0" d="m 178,518 v -24 h 24 v 24 z"/>\s*)'
    r'<path style="[^"]*" (?P<id>id="path\d+") d="[^"]*"/>')
STATES = ("normal", "focused", "pressed", "disabled")


def rgb(value):
    value = value[1:]
    if len(value) == 3:
        value = "".join(c * 2 for c in value)
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def lightness(c):
    return sum(c) / 3 / 255


def role(colour, context):
    c = rgb(colour)
    if c == (0, 0, 0):
        return None
    if c == (255, 255, 255):
        if context and context.startswith(ON_ACCENT):
            return "{{ background }}"
        return "{{ foreground }}"
    spread = max(c) - min(c)
    hue, sat, _ = colorsys.rgb_to_hsv(*(x / 255 for x in c))
    if spread <= 16:
        t = (lightness(c) - lightness(REF_BG)) / (1 - lightness(REF_BG))
        return "{{ shade(%.3f) }}" % t
    if 190 <= hue * 360 <= 235 and sat > 0.3:
        if context and context.startswith(TINTED):
            return "{{ selection(0.5) }}"
        ref = lightness(REF_ACCENT)
        own = lightness(c)
        t = (own - ref) / (1 - ref) if own >= ref else -(ref - own) / ref
        return "{{ accent(%.3f) }}" % t
    if c == (0xFA, 0x23, 0x00):  # tab-close on hover
        return "{{ color1 }}"
    return None


# The gradient whose stops an element's fill ends up drawn with.
def stops_of(element):
    tag = re.search(r'<[^>]*\bid="%s"[^>]*>' % element, text).group(0)
    target = re.search(r"fill:url\(#([\w-]+)\)", tag).group(1)
    while True:
        tag = re.search(r'<linearGradient\b[^>]*\bid="%s"[^>]*>' % target, text).group(0)
        follow = re.search(r'xlink:href="#([\w-]+)"', tag)
        if follow is None:
            return target
        target = follow.group(1)


GLASS_GRADIENTS = {stops_of(dialog) for dialog in DIALOGS}


def glass(attrs):
    tinted, count = OPACITY.subn(r"\1:{{ window_opacity() }}", attrs, count=1)
    return ' class="tint"' + tinted if count else attrs


def rewrite(attrs, context):
    if context in SELECTION:
        return COLOUR.sub("{{ %s }}" % SELECTION[context], attrs, count=1)

    def swap(match):
        new = role(match.group(0), context)
        return new if new else match.group(0)

    return COLOUR.sub(swap, attrs)


def chevron(match):
    state = match.group("id").rsplit("-", 1)[1]
    x, y = float(match.group("x")) + 12, 595.493
    d = "M %g,%g %g,%g %g,%g" % (x - 7, y + 3.5, x, y - 3.5, x + 7, y + 3.5)
    return '%s<path style="%s" d="%s"/>' % (match.group(1), CHEVRON_STYLE % CHEVRON[state], d)


def combo_chevron(match):
    style = CHEVRON_STYLE % CHEVRON[match.group("state")]
    return '%s<path style="%s" %s d="M 185,503 190,498 195,503"/>' % (match.group(1), style, match.group("id"))


# Plain arrows (the breadcrumb's, spin boxes', tree expanders') are the
# toolbar's; a menu's submenu arrow is pressed while its item is highlighted.
def aliases():
    uses = ['<use width="100%%" height="100%%" xlink:href="#tarrow-%s-%s" id="arrow-%s-%s"/>' % (d, s, d, s)
            for d in ("up", "down", "left", "right") for s in STATES]
    for d in ("right", "left"):
        for s, source in (("normal", "arrow-%s-normal"), ("pressed", "menuitem-%s-focused"),
                          ("disabled", "arrow-%s-disabled")):
            uses.append('<use width="100%%" height="100%%" xlink:href="#%s" id="menuitem-%s-%s"/>'
                        % (source % d, d, s))
    return "\n".join(uses) + "\n"


TAG = re.compile(r"<(/?)([A-Za-z][\w:.-]*)((?:[^>\"']|\"[^\"]*\"|'[^']*')*?)(/?)>", re.S)
out, stack, ids, pos = [], [], [], 0
for m in TAG.finditer(text):
    out.append(text[pos:m.start()])
    closing, name, attrs, selfclose = m.groups()
    if closing:
        stack.pop()
        ids.pop()
        out.append(m.group(0))
    else:
        found = re.search(r'\bid="([^"]*)"', attrs)
        own = found.group(1) if found and not AUTO_ID.match(found.group(1)) else None
        context = own or (stack[-1] if stack else None)
        attrs = rewrite(attrs, context)
        if own in WINDOWS or (name == "stop" and ids and ids[-1] in GLASS_GRADIENTS):
            attrs = glass(attrs)
        out.append("<%s%s%s>" % (name, attrs, selfclose))
        if not selfclose:
            stack.append(context)
            ids.append(found.group(1) if found else None)
    pos = m.end()
out.append(text[pos:])
svg = "".join(out)
svg, heads = ARROWHEAD.subn(chevron, svg)
svg, combos = COMBO_ARROW.subn(combo_chevron, svg)
if (heads, combos) != (9, 2):
    sys.exit("expected 9 arrowheads and 2 combo arrows in %s, found %d and %d" % (src, heads, combos))
svg = svg.replace("</svg>", aliases() + "</svg>")

HEADER = """{#- Rendered to ~/.config/Kvantum/Wallust/Wallust.svg: KvMojave's SVG with its
    colours put on the palette, written by scripts/kvantum-template.py. Edit a
    colour by its role; see .github/THEMING.md. -#}
{%- from "palette.jinja" import shade, accent, selection -%}
{%- from "appearance.jinja" import window_opacity -%}
"""
open(dst, "w").write(HEADER + svg)
