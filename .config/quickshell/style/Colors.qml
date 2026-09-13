// style/Colors.qml
pragma Singleton
import QtQuick

QtObject {
    id: root

    readonly property QtObject text: QtObject {
        readonly property color base: "white"
        // De-emphasized text: secondary labels, inline actions, empty states.
        // Previously these all reached for `base.border`, which is a border
        // color that happened to look right — see llm.md §6 on semantic names.
        readonly property color muted: "#9a9a9a"
        // Text drawn on top of an accent fill (a selected calendar day),
        // where `base` would disappear into it.
        readonly property color inverted: "#0f0f0f"
    }

    readonly property QtObject base: QtObject {
        id: baseColors

        readonly property color border: "#646464"
        readonly property color base: "#0f0f0f"
        readonly property color panel: "transparent"
        readonly property real opacity: 0.5

        // The translucent panel fill shared by the bar, every WidgetPopup and
        // the launcher. Composed once here instead of each surface repeating
        // Qt.rgba(Colors.base.base.r, ...).
        readonly property color surface: Qt.rgba(baseColors.base.r, baseColors.base.g, baseColors.base.b, baseColors.opacity)

        // Hover/highlight wash for rows inside a surface (power menu, launcher).
        readonly property color hover: Qt.rgba(1, 1, 1, 0.08)

        // Full-screen dim behind a modal surface: the launcher's backdrop.
        readonly property color scrim: Qt.rgba(0, 0, 0, 0.35)
    }

    // Accents. The hexes already in this file (#61afef, #e06c75, #4caf50)
    // were One Dark's; the rest of the palette was plain CSS colour names
    // ("blue", "red", "purple", "orange") which read far harsher next to
    // them, especially over a light wallpaper. They are One Dark's now too,
    // so the whole file is one palette (llm.md §7).
    readonly property QtObject accent: QtObject {
        readonly property color blue: "#61afef"
        readonly property color red: "#e06c75"
        readonly property color green: "#98c379"
        readonly property color yellow: "#e5c07b"
        readonly property color purple: "#c678dd"
        readonly property color cyan: "#56b6c2"
        readonly property color orange: "#d19a66"
    }

    readonly property QtObject bluetooth: QtObject {
        readonly property color connected: root.accent.blue
        readonly property color disconnected: root.accent.red
        readonly property color pairing: root.accent.purple
    }

    // Battery state colors, consumed by BatteryWidget's icon/label tiering.
    readonly property QtObject battery: QtObject {
        readonly property color normal: "white"
        readonly property color low: root.accent.orange
        readonly property color critical: root.accent.red
        readonly property color charging: root.accent.green
    }

    // Wi-Fi connection state, consumed by WifiWidget.
    readonly property QtObject wifi: QtObject {
        readonly property color connected: root.accent.blue
        readonly property color disconnected: "#646464"
    }

    // Volume/mute state, consumed by VolumeWidget.
    readonly property QtObject volume: QtObject {
        readonly property color normal: "white"
        readonly property color muted: root.accent.orange
    }

    // Hyprland workspace dots, consumed by WorkspaceWidget and the
    // workspace dropdown's tiles.
    readonly property QtObject workspaces: QtObject {
        readonly property color active: "white"
        readonly property color inactive: "#646464"
        // A workspace that exists and holds windows but isn't the active one:
        // brighter than empty, dimmer than active.
        readonly property color occupied: "#9a9a9a"
    }

    // The CPU/memory meters next to the workspaces.
    // The load and brightness ramps.
    readonly property QtObject usage: QtObject {
        readonly property color normal: "#9a9a9a"
        readonly property color warn: root.accent.orange
    }

    // Calendar dropdown, consumed by CalendarPanel. `today` rings the
    // current day in the month grid; `event` is the dot under a day that
    // has events, and the accent on an agenda row's time.
    readonly property QtObject calendar: QtObject {
        readonly property color today: root.accent.blue
        readonly property color event: root.accent.blue
        // Fill behind the day the agenda below the grid is showing. The
        // number on top of it switches to `text.inverted`.
        readonly property color selected: root.accent.blue
    }

    // Power/session menu, consumed by PowerWidget. "danger" marks
    // destructive actions (reboot/shutdown) apart from lock/logout.
    readonly property QtObject power: QtObject {
        readonly property color normal: "white"
        readonly property color danger: root.accent.red
    }

    // Failed actions surfaced inline (e.g. a Wi-Fi connection that needs a
    // PSK Quickshell doesn't know yet).
    readonly property QtObject status: QtObject {
        readonly property color error: root.accent.red
    }

    // Session lock (lock/). Its own background rather than base.surface
    // because nothing shows through a lock surface — there is no desktop
    // behind it to tint, only the compositor's own black.
    readonly property QtObject lock: QtObject {
        readonly property color background: "#0b0b0b"
        // The password field's resting fill and the ring around it.
        readonly property color field: Qt.rgba(1, 1, 1, 0.06)
        readonly property color fieldBorder: "#646464"
        // The ring while PAM has the answer and hasn't replied yet.
        readonly property color busy: root.accent.blue
    }
}
