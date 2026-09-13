// panels/BatteryDetail.qml
//
// One label/value row of BatteryPanel. Its own file rather than an inline
// component, matching PowerAction — the project keeps a repeated row in a
// file of its own.
import QtQuick
import "../style"

Item {
    id: root

    property string label: ""
    property string value: ""

    width: parent ? parent.width : implicitWidth
    // Collapses rather than leaving a gap when a value isn't reported.
    height: visible ? Style.popup.itemHeight : 0

    Text {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        text: root.label
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
    }

    Text {
        id: value
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        text: root.value
        color: Colors.text.base
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
        elide: Text.ElideRight
        // Whatever the label doesn't need.
        width: Math.min(implicitWidth, root.width / 2)
        horizontalAlignment: Text.AlignRight
    }
}
