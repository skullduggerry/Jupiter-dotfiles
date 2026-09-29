pragma ComponentBehavior: Bound

import "../../services"
import "../../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: root.screen ? Hyprland.monitorFor(root.screen) : null

    implicitWidth: row.implicitWidth
    implicitHeight: Style.bar.height

    Row {
        id: row

        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.workspaces.spacing

        Repeater {
            model: Hyprland.workspaces

            delegate: Item {
                id: cell

                required property HyprlandWorkspace modelData
                readonly property bool onThisMonitor: cell.modelData !== null && root.monitor !== null && cell.modelData.monitor === root.monitor
                readonly property bool workspaceActive: cell.modelData !== null && cell.modelData.active
                readonly property bool occupied: cell.modelData !== null && cell.modelData.toplevels.values.length > 0

                visible: cell.onThisMonitor
                width: visible ? Style.workspaces.cellSize : 0
                height: Style.workspaces.cellSize

                Rectangle {
                    id: dot

                    anchors.centerIn: parent
                    width: cell.workspaceActive ? Style.workspaces.activeSize : Style.workspaces.size
                    height: width
                    radius: width / 2
                    color: cell.workspaceActive ? Colors.workspaces.active : cell.occupied ? Colors.workspaces.occupied : Colors.workspaces.inactive

                    Behavior on width {
                        NumberAnimation {
                            duration: Style.animation.normal
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: cell.modelData.activate()
                }
            }
        }
    }

    // The dropdown's workspace zone rather than a popup of its own, like the
    // clock's calendar, so the arrow keys carry on from it to the next zone.
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: DropdownState.toggle(DropdownState.zoneWorkspaces, root.screen)
    }
}
