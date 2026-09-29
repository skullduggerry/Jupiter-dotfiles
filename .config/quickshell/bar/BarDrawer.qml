import "../style"
import QtQuick

Item {
    id: root

    required property bool expanded
    default property alias content: items.data
    readonly property real fullWidth: items.implicitWidth > 0 ? items.implicitWidth + Style.bar.spacing : 0
    property real progress: root.expanded ? 1 : 0

    implicitWidth: root.fullWidth * root.progress
    implicitHeight: Style.bar.height
    clip: true

    Row {
        id: items

        spacing: Style.bar.spacing

        anchors {
            right: parent.right
            rightMargin: Style.bar.spacing
            verticalCenter: parent.verticalCenter
        }
    }

    Behavior on progress {
        NumberAnimation {
            duration: Style.animation.slow
            easing.type: Easing.OutCubic
        }
    }
}
