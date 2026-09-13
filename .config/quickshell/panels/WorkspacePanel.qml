// panels/WorkspacePanel.qml
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../style"

Item {
    id: root

    required property ShellScreen screen

    readonly property bool wantsKeyboard: false

    readonly property int preferredHeight: Style.bar.padding * 2
        + header.height
        + Style.border.width
        + Style.bar.spacing
        + grid.height

    signal activated()

    readonly property HyprlandMonitor monitor: root.screen ? Hyprland.monitorFor(root.screen) : null

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

        Grid {
            id: grid
            anchors {
                top: separator.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.bar.spacing
            }
            columns: Style.workspaces.tileColumns
            spacing: Style.workspaces.tileSpacing

            readonly property real tileWidth:
                (width - Style.workspaces.tileSpacing * (grid.columns - 1)) / grid.columns

            Repeater {
                model: root.workspaces

                delegate: Rectangle {
                    id: tile
                    required property HyprlandWorkspace modelData

                    readonly property int windowCount: tile.modelData.toplevels.values.length

                    width: grid.tileWidth
                    height: Style.workspaces.tileHeight
                    radius: Style.popup.rowRadius
                    color: tileArea.containsMouse ? Colors.base.hover : "transparent"
                    border.width: Style.border.width
                    border.color: tile.modelData.active ? Colors.workspaces.active : Colors.base.border

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: Style.widgets.spacing
                            verticalCenter: parent.verticalCenter
                        }
                        width: tile.width - Style.widgets.spacing * 2
                            - (tileCount.visible ? tileCount.width + Style.widgets.spacing : 0)
                        text: tile.modelData.name
                        color: tile.modelData.active ? Colors.workspaces.active
                            : tile.windowCount > 0 ? Colors.workspaces.occupied
                            : Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.size
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        id: tileCount
                        anchors {
                            right: parent.right
                            rightMargin: Style.widgets.spacing
                            verticalCenter: parent.verticalCenter
                        }
                        visible: tile.windowCount > 0
                        text: tile.windowCount
                        color: Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.smallSize
                    }

                    MouseArea {
                        id: tileArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            tile.modelData.activate()
                            root.activated()
                        }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: root.workspaces.length === 0
            text: "No workspaces on this monitor"
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }
    }
}
