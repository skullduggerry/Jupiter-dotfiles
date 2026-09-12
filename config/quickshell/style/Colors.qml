// style/Colors.qml
pragma Singleton
import QtQuick

QtObject {
    readonly property QtObject text: QtObject {
        readonly property color base: "white"
        // De-emphasized text: secondary labels, inline actions, empty states.
        // Previously these all reached for `base.border`, which is a border
        // color that happened to look right — see llm.md §6 on semantic names.
        readonly property color muted: "#9a9a9a"
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
    }

    readonly property QtObject bluetooth: QtObject {
        readonly property color connected: "blue"
        readonly property color disconnected: "red"
        readonly property color pairing: "purple"
    }

    // Battery state colors, consumed by BatteryWidget's icon/label tiering.
    readonly property QtObject battery: QtObject {
        readonly property color normal: "white"
        readonly property color low: "orange"
        readonly property color critical: "red"
        readonly property color charging: "#4caf50"
    }

    // Wi-Fi connection state, consumed by WifiWidget.
    readonly property QtObject wifi: QtObject {
        readonly property color connected: "blue"
        readonly property color disconnected: "#646464"
    }

    // Volume/mute state, consumed by VolumeWidget.
    readonly property QtObject volume: QtObject {
        readonly property color normal: "white"
        readonly property color muted: "orange"
    }

    // Hyprland workspace pips, consumed by WorkspaceWidget.
    readonly property QtObject workspaces: QtObject {
        readonly property color active: "white"
        readonly property color inactive: "#646464"
    }

    // Power/session menu, consumed by PowerWidget. "danger" marks
    // destructive actions (reboot/shutdown) apart from lock/logout.
    readonly property QtObject power: QtObject {
        readonly property color normal: "white"
        readonly property color danger: "red"
    }

    // Failed actions surfaced inline (e.g. a Wi-Fi connection that needs a
    // PSK Quickshell doesn't know yet).
    readonly property QtObject status: QtObject {
        readonly property color error: "#e06c75"
    }
}
