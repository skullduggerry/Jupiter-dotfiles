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
}
