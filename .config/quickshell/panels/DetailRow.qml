import "../style"
import QtQuick

Item {
    id: root

    property string label: ""
    property string value: ""

    width: parent ? parent.width : implicitWidth
    height: visible ? Style.popup.itemHeight : 0

    Text {
        text: root.label
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
    }

    Text {
        id: value

        text: root.value
        color: Colors.text.base
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
        elide: Text.ElideRight
        width: Math.min(implicitWidth, root.width / 2)
        horizontalAlignment: Text.AlignRight

        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
    }
}
