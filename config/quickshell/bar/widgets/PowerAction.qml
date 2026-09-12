// bar/widgets/PowerAction.qml
//
// One row in the power/session menu (see PowerWidget.qml): a label plus a
// hover state, firing `activated()` on click.
import QtQuick
import "../../style"

Rectangle {
    id: root

    property string label: ""
    property color labelColor: Colors.text.base
    signal activated()

    width: parent ? parent.width : implicitWidth
    height: Style.popup.itemHeight
    radius: Style.bar.radius / 2
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
