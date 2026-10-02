import "../../style"
import QtQuick

// A row of the power menu. Highlighted is the one the arrow keys are on, which
// the pointer moves too, so the menu shows one highlight at a time.
Rectangle {
    id: root

    property string label: ""
    property color labelColor: Colors.text.base
    property bool highlighted: false

    signal activated
    signal hovered

    width: parent ? parent.width : implicitWidth
    height: Style.popup.itemHeight
    radius: Style.popup.rowRadius
    color: root.highlighted ? Colors.base.hover : "transparent"

    Text {
        anchors.centerIn: parent
        text: root.label
        color: root.labelColor
        font.family: Style.text.font
        font.pixelSize: Style.text.size
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered()
        onClicked: root.activated()
    }
}
