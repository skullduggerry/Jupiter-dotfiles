// bar/widgets/WorkspaceWidget.qml
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../style"

Item {
    id: root

    // The screen this bar instance belongs to (passed down from Bar.qml ->
    // BarContent.qml, same value PanelWindow.screen already gets in
    // Bar.qml). Used to show only the workspaces that live on this
    // monitor, per PROJECT_STRUCTURE.md's multi-monitor guidance.
    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: screen ? Hyprland.monitorFor(screen) : null

    implicitWidth: row.implicitWidth
    implicitHeight: Style.bar.height

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.workspaces.spacing

        Repeater {
            model: Hyprland.workspaces

            delegate: Rectangle {
                id: pill
                required property HyprlandWorkspace modelData

                // Only render workspaces that belong to this widget's
                // monitor; Hyprland.workspaces is global across monitors.
                visible: root.monitor !== null && pill.modelData.monitor === root.monitor

                width: pill.modelData.active ? Style.workspaces.activeWidth : Style.workspaces.size
                height: Style.workspaces.size
                radius: height / 2
                color: pill.modelData.active ? Colors.workspaces.active : Colors.workspaces.inactive
                border.width: pill.modelData.focused ? Style.border.width : 0
                border.color: Colors.workspaces.active

                Behavior on width {
                    NumberAnimation { duration: 120 }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: pill.modelData.activate()
                }
            }
        }
    }
}
