// style/Colors.qml
pragma Singleton
import QtQuick

QtObject {
    readonly property QtObject text: QtObject {
        readonly property color base: "white"
    }

    readonly property QtObject base: QtObject {
        readonly property color border: "#646464"
        readonly property color base: "#0f0f0f"
        readonly property color panel: "transparent"
        readonly property real opacity: 0.5
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
}
