import "../../style"
import QtQuick

Item {
    id: root

    required property real value
    readonly property list<string> ramp: ["\u{F0130}", "\u{F0A9E}", "\u{F0A9F}", "\u{F0AA0}", "\u{F0AA1}", "\u{F0AA2}", "\u{F0AA3}", "\u{F0AA4}", "\u{F0AA5}"]

    implicitWidth: Style.text.iconSize + Style.widgets.spacing
    implicitHeight: Style.bar.height

    Text {
        anchors.centerIn: parent
        text: root.ramp[Math.round(Math.max(0, Math.min(1, root.value)) * (root.ramp.length - 1))]
        color: root.value > Style.usage.warnAbove ? Colors.usage.warn : Colors.usage.normal
        font.family: Style.text.font
        font.pixelSize: Style.text.iconSize
    }
}
