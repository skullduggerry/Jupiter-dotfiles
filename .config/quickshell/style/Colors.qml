pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    id: root

    // Everything below derives from these, which come from the theme wallust
    // rendered (Theme.palette). Without one, they are the colours the shell
    // was designed with, and every derived value comes out as it always was.
    component PaletteColors: QtObject {
        id: palette

        readonly property color background: Theme.palette.background || "#0f0f0f"
        readonly property color foreground: Theme.palette.foreground || "white"
        readonly property color blue: root.slot(Theme.palette.color4, "#61afef")
        readonly property color red: root.slot(Theme.palette.color1, "#e06c75")
        readonly property color green: root.slot(Theme.palette.color2, "#98c379")
        readonly property color yellow: root.slot(Theme.palette.color3, "#e5c07b")
        readonly property color purple: root.slot(Theme.palette.color5, "#c678dd")
        readonly property color cyan: root.slot(Theme.palette.color6, "#56b6c2")
        // Terminal palettes carry no orange; halfway from red to yellow is one.
        readonly property color orange: root.distinct(Theme.palette.color1) && root.distinct(Theme.palette.color3) ? root.mix(palette.red, palette.yellow, 0.5) : "#d19a66"
    }
    readonly property PaletteColors palette: PaletteColors {}

    readonly property bool light: root.palette.background.hslLightness > 0.5
    // What adaptive glass holds muted text to: WCAG AA for body text, or, in
    // a theme whose muted text is softer than that even on a solid surface,
    // this share of the contrast it has there.
    readonly property real readableContrast: 4.5
    readonly property real glassKeeps: 0.9
    readonly property real glassStep: 0.02
    // The least share of the text colour faded text keeps (faded()): where
    // it still reads at readableContrast over the surface, over blur over
    // the backdrop's least readable part too; no fading at all where full
    // text only just does.
    readonly property real fadeFloor: {
        const behind = Theme.blur && root.backdrop.a > 0 ? root.mix(root.backdrop, root.palette.background, root.base.opacity) : root.palette.background;
        for (let share = 0.3; share < 1; share += root.glassStep)
            if (root.contrast(root.mix(root.palette.background, root.palette.foreground, share), behind) >= root.readableContrast)
                return share;
        return 1;
    }
    // The tint the Settings app offers: more than Hyprland's ignore_alpha for
    // the shell's layers (0.05, .config/hypr/styles/layout.lua), below which a
    // surface is not blurred at all, and short of Solid. Light enough for
    // liquid glass; Adaptive raises it where text needs it.
    readonly property real tintLeast: 0.1
    readonly property real tintMost: 0.95
    // How much of the light a clear pane of acrylic's glass (glassTint)
    // absorbs: Hyprland thickens it toward the rim, which reads as depth.
    readonly property real glassAbsorption: 0.35
    // The wallpaper at its least readable behind the panels, over every
    // screen: its brightest under light text, its darkest under dark text.
    // Transparent until a bar has measured one (Theme.backdrops).
    readonly property color backdrop: {
        // Undefined for the moment Theme is still being built.
        const measured = Object.values(Theme.backdrops || {}).map(sample => root.light ? sample.dark : sample.bright);
        if (measured.length === 0)
            return "transparent";

        const brighter = (first, second) => root.luminance(first) >= root.luminance(second) ? first : second;
        const darker = (first, second) => root.luminance(first) <= root.luminance(second) ? first : second;
        return measured.reduce(root.light ? darker : brighter);
    }

    component TextColors: QtObject {
        readonly property color base: root.palette.foreground
        // Brighter than the apps' inactive text (templates' shade(0.58)): it is
        // read over glass.
        readonly property color muted: root.mix(root.palette.background, root.palette.foreground, 0.7)
        readonly property color inverted: root.palette.background
    }
    readonly property TextColors text: TextColors {}

    component BaseColors: QtObject {
        id: baseColors

        readonly property color border: root.mix(root.palette.background, root.palette.foreground, 0.354)
        readonly property color base: root.palette.background
        readonly property color panel: "transparent"
        // Blur (frosted glass over Hyprland's blur) or Solid. Over blur the
        // surface is at least glassFloor opaque, the tint picked for dark or
        // for light themes (dark text needs more of it); Adaptive raises it as
        // far as muted text needs to read (readableContrast) over the
        // wallpaper behind (root.backdrop), up to glassCeiling, past which
        // glass stops looking like glass.
        readonly property real glassFloor: Math.max(root.tintLeast, Math.min(root.tintMost, root.light ? Theme.lightTint : Theme.darkTint))
        readonly property real glassCeiling: Math.max(baseColors.glassFloor, root.light ? 0.88 : 0.72)
        readonly property real opacity: !Theme.blur ? 1 : Theme.adaptiveTint ? root.glassOver(root.backdrop) : baseColors.glassFloor
        readonly property color surface: root.withAlpha(baseColors.base, baseColors.opacity)
        // The blur variant's material (BlurVariants): clear shows the
        // backdrop sharp, specular draws a curved rim of its own, which the
        // glass's outline (edge) and the light on its upper half (highlight)
        // follow rather than a flat border.
        readonly property var variant: BlurVariants.find(Theme.blurVariant)
        readonly property bool clear: Theme.blur && baseColors.variant.clear === true
        readonly property bool specular: Theme.blur && baseColors.variant.specular === true
        readonly property color edge: baseColors.specular ? root.withAlpha(root.palette.foreground, 0.2) : baseColors.border
        readonly property color highlight: !baseColors.specular ? "transparent" : root.light ? root.withAlpha(root.palette.background, 0.55) : root.withAlpha(root.palette.foreground, 0.1)
        // The drawn rim (panels/GlassHighlight): its outermost band, the
        // thickest glass, in the glass's own colour, and the light caught
        // where it meets the clear middle.
        readonly property color lensBand: root.withAlpha(root.palette.background, 0.4)
        readonly property color caustic: root.light ? root.withAlpha(root.palette.background, 0.35) : root.withAlpha(root.palette.foreground, 0.06)
        // What Hyprland colours its glass with (services/HyprBlur): acrylic's
        // pane in the theme's background, aurora's curtains in the accent and
        // a second accent, the fluid jar's liquid in the accent.
        readonly property color glassTint: root.withAlpha(root.palette.background, root.glassAbsorption)
        readonly property color glowFirst: root.accent.primary
        readonly property color glowSecond: root.accentColor(Theme.accent === "purple" ? "cyan" : "purple")
        readonly property color fluid: root.withAlpha(root.accent.primary, 0.8)
        readonly property color hover: root.withAlpha(root.palette.foreground, 0.08)
        readonly property color scrim: Qt.rgba(0, 0, 0, 0.35)
    }
    readonly property BaseColors base: BaseColors {}

    component IconColors: QtObject {
        readonly property color active: root.text.base
        readonly property color disabled: root.base.border
        // Under a meter's value (icons/RingIcon).
        readonly property color track: root.withAlpha(root.palette.foreground, 0.16)
    }
    readonly property IconColors icon: IconColors {}

    // The accents the Settings app offers, in its order. The design's pink is
    // cyan here: a terminal palette has a cyan slot and no pink.
    readonly property list<string> accentNames: ["blue", "purple", "cyan", "green", "orange", "red"]
    component AccentColors: QtObject {
        readonly property color blue: root.palette.blue
        readonly property color red: root.palette.red
        readonly property color green: root.palette.green
        readonly property color yellow: root.palette.yellow
        readonly property color purple: root.palette.purple
        readonly property color cyan: root.palette.cyan
        readonly property color orange: root.palette.orange
        // The one the Settings app picked; what every "accent" below is.
        readonly property color primary: root.accentColor(Theme.accent)
    }
    readonly property AccentColors accent: AccentColors {}

    component BluetoothColors: QtObject {
        readonly property color connected: root.accent.primary
        readonly property color disconnected: root.accent.red
        readonly property color pairing: root.accent.purple
    }
    readonly property BluetoothColors bluetooth: BluetoothColors {}

    component BatteryColors: QtObject {
        readonly property color normal: root.icon.active
        readonly property color low: root.accent.orange
        readonly property color critical: root.accent.red
        readonly property color charging: root.accent.green
    }
    readonly property BatteryColors battery: BatteryColors {}

    component WifiColors: QtObject {
        readonly property color connected: root.accent.primary
        readonly property color disconnected: root.base.border
    }
    readonly property WifiColors wifi: WifiColors {}

    component WorkspacesColors: QtObject {
        readonly property color active: root.text.base
        readonly property color inactive: root.base.border
        readonly property color occupied: root.text.muted
    }
    readonly property WorkspacesColors workspaces: WorkspacesColors {}

    component UsageColors: QtObject {
        readonly property color normal: root.icon.active
        readonly property color warn: root.accent.orange
    }
    readonly property UsageColors usage: UsageColors {}

    component CalendarColors: QtObject {
        readonly property color today: root.accent.primary
        readonly property color event: root.accent.primary
        readonly property color selected: root.accent.primary
    }
    readonly property CalendarColors calendar: CalendarColors {}

    component NotificationColors: QtObject {
        readonly property color urgent: root.accent.red
        readonly property color badge: root.accent.primary
    }
    readonly property NotificationColors notification: NotificationColors {}

    component MenuColors: QtObject {
        readonly property color checked: root.accent.primary
    }
    readonly property MenuColors menu: MenuColors {}

    component PowerColors: QtObject {
        readonly property color normal: root.text.base
        readonly property color danger: root.accent.red
    }
    readonly property PowerColors power: PowerColors {}

    component StatusColors: QtObject {
        readonly property color error: root.accent.red
    }
    readonly property StatusColors status: StatusColors {}

    // Drawn over a picture under a dark scrim rather than over the shell's own
    // surface, so these keep the shell's light-on-dark whatever the theme is.
    component OverlayColors: QtObject {
        readonly property color scrim: root.base.scrim
        readonly property color text: "white"
        readonly property color muted: "#9a9a9a"
        readonly property color border: "#646464"
        readonly property color inverted: "#0f0f0f"
    }
    readonly property OverlayColors overlay: OverlayColors {}

    // Left Ctrl tapped twice (cursor/): the overlay's scrim, darker, over
    // everything but the pointer's circle, ringed in the accent.
    component CursorFinderColors: QtObject {
        readonly property color scrim: root.withAlpha(root.overlay.scrim, 0.55)
        readonly property color ring: root.accent.primary
    }
    readonly property CursorFinderColors cursorFinder: CursorFinderColors {}

    component PillColors: QtObject {
        readonly property color idle: root.withAlpha(root.palette.foreground, 0.05)
        readonly property color selected: root.withAlpha(root.palette.foreground, 0.14)
    }
    readonly property PillColors pill: PillColors {}

    // The lock and login screens. With the Lock Screen tab's Theme on the
    // desktop's, they are the theme's: its text over a veil of its background,
    // and its surface for the field (glass where Blur is on). Otherwise they
    // are over the wallpaper as the overlay is, and only the accent follows.
    component LockColors: QtObject {
        id: lockColors

        readonly property bool themed: LockLook.followTheme
        readonly property color background: lockColors.themed ? root.palette.background : "#0b0b0b"
        readonly property color text: lockColors.themed ? root.text.base : root.overlay.text
        readonly property color muted: lockColors.themed ? root.text.muted : root.overlay.muted
        readonly property color field: lockColors.themed ? root.base.surface : Qt.rgba(1, 1, 1, 0.06)
        readonly property color fieldBorder: lockColors.themed ? root.base.border : root.overlay.border
        readonly property color busy: root.accent.primary
        // As strong as Appearance's Lock Screen tab's Dim says.
        readonly property color scrim: lockColors.themed ? root.withAlpha(root.palette.background, LockLook.dim) : Qt.rgba(0, 0, 0, LockLook.dim)
    }
    readonly property LockColors lock: LockColors {}

    // A generated palette fills the ANSI slots by brightness rather than hue,
    // so a slot only stands in for its colour when it is saturated and stands
    // off the background: a wallpaper that is all greys keeps the shell's red.
    function distinct(value: string): bool {
        if (value === "")
            return false;

        const candidate = Qt.color(value);
        return candidate.hslSaturation >= 0.25 && root.contrast(candidate, root.palette.background) >= 2;
    }

    // The least surface opacity, in steps from glassFloor to glassCeiling, at
    // which muted text over it and the backdrop reads (readableContrast).
    function glassOver(backdrop: color): real {
        const floor = root.base.glassFloor;
        const ceiling = root.base.glassCeiling;
        if (backdrop.a === 0)
            return floor;

        const target = Math.min(root.readableContrast, root.glassKeeps * root.contrast(root.text.muted, root.palette.background));
        for (let opacity = floor; opacity < ceiling; opacity += root.glassStep)
            if (root.contrast(root.text.muted, root.mix(backdrop, root.palette.background, opacity)) >= target)
                return opacity;
        return ceiling;
    }

    // WCAG's contrast ratio, from 1 (identical) to 21 (black on white).
    function contrast(first: color, second: color): real {
        const lighter = Math.max(root.luminance(first), root.luminance(second));
        const darker = Math.min(root.luminance(first), root.luminance(second));
        return (lighter + 0.05) / (darker + 0.05);
    }

    function luminance(value: color): real {
        const channel = c => c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
        return 0.2126 * channel(value.r) + 0.7152 * channel(value.g) + 0.0722 * channel(value.b);
    }

    function accentColor(name: string): color {
        switch (name) {
        case "purple":
            return root.palette.purple;
        case "cyan":
            return root.palette.cyan;
        case "green":
            return root.palette.green;
        case "orange":
            return root.palette.orange;
        case "red":
            return root.palette.red;
        default:
            return root.palette.blue;
        }
    }

    // Text toward its surface by `amount` (0 to 1), as the quick menu's wheel
    // fades its rows away from the middle: at most down to fadeFloor.
    function faded(full: color, amount: real): color {
        return root.mix(root.palette.background, full, 1 - (1 - root.fadeFloor) * Math.max(0, Math.min(1, amount)));
    }

    function slot(value: string, fallback: color): color {
        return root.distinct(value) ? value : fallback;
    }

    function mix(from: color, to: color, amount: real): color {
        return Qt.tint(from, Qt.rgba(to.r, to.g, to.b, amount));
    }

    // A colour as Hyprland's options take it: rgba(rrggbbaa).
    function hyprland(value: color): string {
        const hex = channel => Math.round(channel * 255).toString(16).padStart(2, "0");
        return `rgba(${hex(value.r)}${hex(value.g)}${hex(value.b)}${hex(value.a)})`;
    }

    function withAlpha(base: color, alpha: real): color {
        return Qt.rgba(base.r, base.g, base.b, alpha);
    }
}
