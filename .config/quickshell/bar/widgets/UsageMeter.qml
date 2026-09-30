import "../../icons"
import "../../style"
import QtQuick

Item {
    id: root

    required property real value

    implicitWidth: Style.text.iconSize + Style.widgets.spacing
    implicitHeight: Style.bar.height

    RingIcon {
        anchors.centerIn: parent
        value: root.value
        color: root.value > Style.usage.warnAbove ? Colors.usage.warn : Colors.usage.normal
    }
}
