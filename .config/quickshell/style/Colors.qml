// style/Colors.qml
pragma Singleton
import QtQuick

QtObject {
    id: root

    readonly property QtObject text: QtObject {
        readonly property color base: "white"
        readonly property color muted: "#9a9a9a"
        readonly property color inverted: "#0f0f0f"
    }

    readonly property QtObject base: QtObject {
        id: baseColors

        readonly property color border: "#646464"
        readonly property color base: "#0f0f0f"
        readonly property color panel: "transparent"
        readonly property real opacity: 0.5

        readonly property color surface: Qt.rgba(baseColors.base.r, baseColors.base.g, baseColors.base.b, baseColors.opacity)

        readonly property color hover: Qt.rgba(1, 1, 1, 0.08)

        readonly property color scrim: Qt.rgba(0, 0, 0, 0.35)
    }

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

    readonly property QtObject battery: QtObject {
        readonly property color normal: "white"
        readonly property color low: root.accent.orange
        readonly property color critical: root.accent.red
        readonly property color charging: root.accent.green
    }

    readonly property QtObject wifi: QtObject {
        readonly property color connected: root.accent.blue
        readonly property color disconnected: "#646464"
    }

    readonly property QtObject volume: QtObject {
        readonly property color normal: "white"
        readonly property color muted: root.accent.orange
    }

    readonly property QtObject workspaces: QtObject {
        readonly property color active: "white"
        readonly property color inactive: "#646464"
        readonly property color occupied: "#9a9a9a"
    }

    readonly property QtObject usage: QtObject {
        readonly property color normal: "#9a9a9a"
        readonly property color warn: root.accent.orange
    }

    readonly property QtObject calendar: QtObject {
        readonly property color today: root.accent.blue
        readonly property color event: root.accent.blue
        readonly property color selected: root.accent.blue
    }

    readonly property QtObject notification: QtObject {
        readonly property color urgent: root.accent.red
        readonly property color badge: root.accent.blue
    }

    readonly property QtObject menu: QtObject {
        readonly property color checked: root.accent.blue
    }

    readonly property QtObject power: QtObject {
        readonly property color normal: "white"
        readonly property color danger: root.accent.red
    }

    readonly property QtObject status: QtObject {
        readonly property color error: root.accent.red
    }

    readonly property QtObject lock: QtObject {
        readonly property color background: "#0b0b0b"
        readonly property color field: Qt.rgba(1, 1, 1, 0.06)
        readonly property color fieldBorder: "#646464"
        readonly property color busy: root.accent.blue
    }
}
