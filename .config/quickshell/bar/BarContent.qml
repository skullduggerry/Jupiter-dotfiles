// bar/BarContent.qml
import QtQuick
import Quickshell
import "../style"
import "./widgets"

Rectangle {
    id: root

    // Forwarded from Bar.qml's PanelWindow.screen so per-widget popups and
    // the workspace widget can filter to this bar's own monitor.
    required property ShellScreen screen

    anchors.fill: parent
    anchors.margins: 1
    radius: Style.bar.radius
    color: Colors.base.surface
    border.color: Colors.base.border
    border.width: Style.border.width

    Row {
        id: left
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        anchors.leftMargin: Style.bar.padding
        spacing: Style.bar.spacing

        WorkspaceWidget { screen: root.screen }
        BarSeparator {}
        SystemUsageWidget {}
    }

    Row {
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
        spacing: Style.bar.spacing
        ClockWidget { screen: root.screen }
    }

    Row {
        id: right
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        anchors.rightMargin: Style.bar.padding
        spacing: Style.bar.spacing

        SystemTrayWidget {}
        BrightnessWidget {}
        VolumeWidget {}
        WifiWidget { screen: root.screen }
        BluetoothWidget { screen: root.screen }
        BatteryWidget { screen: root.screen }
        PowerWidget { screen: root.screen }
    }
}
