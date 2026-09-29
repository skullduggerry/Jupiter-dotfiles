import "../../style"
import QtQuick

Rectangle {
    id: root

    property string label: ""
    property color labelColor: Colors.text.base

    signal activated

    width: parent ? parent.width : implicitWidth
    height: Style.popup.itemHeight
    radius: Style.popup.rowRadius
    color: area.containsMouse ? Colors.base.hover : "transparent"

    Text {
        anchors.centerIn: parent
        text: root.label
        color: root.labelColor
        font.family: Style.text.font
        font.pixelSize: Style.text.size
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.activated()
    }
}
