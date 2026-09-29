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

    component TextColors: QtObject {
        readonly property color base: root.palette.foreground
        readonly property color muted: root.mix(root.palette.background, root.palette.foreground, 0.58)
        readonly property color inverted: root.palette.background
    }
    readonly property TextColors text: TextColors {}

    component BaseColors: QtObject {
        id: baseColors

        readonly property color border: root.mix(root.palette.background, root.palette.foreground, 0.354)
        readonly property color base: root.palette.background
        readonly property color panel: "transparent"
        // Blur (frosted glass over Hyprland's blur) or Solid; a light theme's
        // dark text needs more of its surface to stay readable.
        readonly property real opacity: !Theme.blur ? 1 : baseColors.base.hslLightness > 0.5 ? 0.8 : 0.5
        readonly property color surface: root.withAlpha(baseColors.base, baseColors.opacity)
        readonly property color hover: root.withAlpha(root.palette.foreground, 0.08)
        readonly property color scrim: Qt.rgba(0, 0, 0, 0.35)
    }
    readonly property BaseColors base: BaseColors {}

    component IconColors: QtObject {
        readonly property color active: root.text.base
        readonly property color disabled: root.base.border
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

    component PillColors: QtObject {
        readonly property color idle: root.withAlpha(root.palette.foreground, 0.05)
        readonly property color selected: root.withAlpha(root.palette.foreground, 0.14)
    }
    readonly property PillColors pill: PillColors {}

    component LockColors: QtObject {
        // Over the wallpaper, like the overlay: only the accent follows the theme.
        readonly property color background: "#0b0b0b"
        readonly property color text: root.overlay.text
        readonly property color muted: root.overlay.muted
        readonly property color field: Qt.rgba(1, 1, 1, 0.06)
        readonly property color fieldBorder: root.overlay.border
        readonly property color busy: root.accent.primary
        readonly property color scrim: Qt.rgba(0, 0, 0, 0.45)
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

    function slot(value: string, fallback: color): color {
        return root.distinct(value) ? value : fallback;
    }

    function mix(from: color, to: color, amount: real): color {
        return Qt.tint(from, Qt.rgba(to.r, to.g, to.b, amount));
    }

    function withAlpha(base: color, alpha: real): color {
        return Qt.rgba(base.r, base.g, base.b, alpha);
    }
}
