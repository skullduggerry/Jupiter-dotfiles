import "../../style"
import QtQuick

Item {
    id: root

    required property real value
    readonly property var ramp: ["󰄰", "󰪞", "󰪟", "󰪠", "󰪡", "󰪢", "󰪣", "󰪤", "󰪥"]

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
