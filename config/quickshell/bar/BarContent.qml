// bar/BarContent.qml
import QtQuick
import "../style"
import "./widgets"

Rectangle {
    anchors.fill: parent
    anchors.margins: 1
    radius: Style.bar.radius
    color: Qt.rgba(Colors.base.base.r, Colors.base.base.g, Colors.base.base.b, Colors.base.opacity)
    border.color: Colors.base.border
    border.width: Style.border.width

    // TODO(Phase 2): workspaces widget goes here.
    Row {
        id: left
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: Style.bar.padding
        spacing: Style.bar.spacing
    }

    Row {
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
        spacing: Style.bar.spacing
        ClockWidget {}
    }

    Row {
        id: right
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        anchors.rightMargin: Style.bar.padding
        spacing: Style.bar.spacing
        BluetoothWidget {}
        BatteryWidget {}
    }
}
