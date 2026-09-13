// dropdown/WorkspacePanel.qml
//
// Left zone of the swipe dropdown: the workspaces on this monitor and the
// windows on each of them. The bar's WorkspaceWidget shows the same set as
// pips; this is the version with room for window titles.
//
// Clicking a workspace switches to it, clicking a window focuses it — both
// through native Quickshell APIs (HyprlandWorkspace.activate() and the
// toplevel's own Wayland activate()) rather than dispatcher strings.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../style"

Item {
    id: root

    required property ShellScreen screen

    // Part of the zone-panel contract in Dropdown.qml.
    readonly property bool wantsKeyboard: false

    // Raised when something in here has been acted on, so the dropdown can
    // get out of the way instead of the panel reaching for shared state.
    signal activated()

    readonly property HyprlandMonitor monitor: root.screen ? Hyprland.monitorFor(root.screen) : null

    // Hyprland.workspaces is global across monitors and in no particular
    // order; this monitor's, by id. An ObjectModel is read through `values`.
    readonly property var workspaces: {
        if (root.monitor === null) return []
        return Hyprland.workspaces.values
            .filter(workspace => workspace.monitor === root.monitor)
            .sort((left, right) => left.id - right.id)
    }

    Item {
        anchors.fill: parent
        anchors.margins: Style.bar.padding

        Item {
            id: header
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: Style.popup.itemHeight

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "Workspaces"
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size
            }

            Text {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: root.monitor ? root.monitor.name : ""
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
            }
        }

        Rectangle {
            id: separator
            anchors { top: header.bottom; left: parent.left; right: parent.right }
            height: Style.border.width
            color: Colors.base.border
        }

        ListView {
            id: workspaceList
            anchors {
                top: separator.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.bar.spacing
            }
            clip: true
            spacing: Style.widgets.spacing
            model: root.workspaces
            visible: count > 0

            delegate: Column {
                id: workspaceEntry
                required property HyprlandWorkspace modelData

                width: workspaceList.width
                spacing: Style.border.width

                Rectangle {
                    id: workspaceRow
                    width: parent.width
                    height: Style.popup.itemHeight
                    radius: Style.bar.radius / 2
                    color: workspaceArea.containsMouse ? Colors.base.hover : "transparent"

                    Rectangle {
                        id: pip
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        width: Style.workspaces.size
                        height: Style.workspaces.size
                        radius: height / 2
                        color: workspaceEntry.modelData.active
                            ? Colors.workspaces.active
                            : Colors.workspaces.inactive
                    }

                    Text {
                        id: workspaceName
                        anchors {
                            left: pip.right
                            leftMargin: Style.bar.spacing
                            verticalCenter: parent.verticalCenter
                        }
                        text: workspaceEntry.modelData.name
                        color: Colors.text.base
                        font.family: Style.text.font
                        font.pixelSize: Style.text.size
                    }

                    Text {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        text: workspaceEntry.modelData.toplevels.values.length
                        color: Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.smallSize
                    }

                    MouseArea {
                        id: workspaceArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            workspaceEntry.modelData.activate()
                            root.activated()
                        }
                    }
                }

                Repeater {
                    model: workspaceEntry.modelData.toplevels

                    delegate: Rectangle {
                        id: windowRow
                        required property HyprlandToplevel modelData

                        // A toplevel Hyprland knows about but that hasn't been
                        // matched to its Wayland handle yet can't be focused,
                        // so it's listed without pretending to be clickable.
                        readonly property bool focusable: windowRow.modelData.wayland !== null

                        width: workspaceEntry.width
                        height: Style.popup.itemHeight
                        radius: Style.bar.radius / 2
                        color: windowArea.containsMouse ? Colors.base.hover : "transparent"

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: Style.workspaces.size + Style.bar.spacing
                            text: windowRow.modelData.title
                            color: windowRow.modelData.activated ? Colors.text.base : Colors.text.muted
                            font.family: Style.text.font
                            font.pixelSize: Style.text.smallSize
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            id: windowArea
                            anchors.fill: parent
                            enabled: windowRow.focusable
                            hoverEnabled: true
                            onClicked: {
                                windowRow.modelData.wayland.activate()
                                root.activated()
                            }
                        }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: workspaceList.count === 0
            text: "No workspaces on this monitor"
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }
    }
}
