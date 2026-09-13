// bar/widgets/WorkspaceWidget.qml
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../panels"
import "../../style"

Item {
    id: root

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

            delegate: Item {
                id: cell
                required property HyprlandWorkspace modelData

                visible: root.monitor !== null && cell.modelData.monitor === root.monitor
                width: visible ? Style.workspaces.cellSize : 0
                height: Style.workspaces.cellSize

                Rectangle {
                    id: dot

                    anchors.centerIn: parent
                    width: cell.modelData.active ? Style.workspaces.activeSize : Style.workspaces.size
                    height: width
                    radius: width / 2
                    color: cell.modelData.active ? Colors.workspaces.active
                        : cell.modelData.toplevels.values.length > 0 ? Colors.workspaces.occupied
                        : Colors.workspaces.inactive

                    Behavior on width {
                        NumberAnimation { duration: Style.animation.normal }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: cell.modelData.activate()
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: workspacePopup.visible = !workspacePopup.visible
    }

    WidgetPopup {
        id: workspacePopup
        screen: root.screen
        anchorItem: root
        namespaceSuffix: "workspaces-popup"
        popupWidth: Style.dropdown.width
        popupHeight: Math.max(Style.popup.minHeight,
                              Math.min(Style.dropdown.maxHeight,
                                       panel.item ? panel.item.preferredHeight : Style.popup.minHeight))

        Loader {
            id: panel
            anchors.fill: parent
            active: workspacePopup.visible

            sourceComponent: WorkspacePanel {
                screen: root.screen
                onActivated: workspacePopup.visible = false
            }
        }
    }
}
