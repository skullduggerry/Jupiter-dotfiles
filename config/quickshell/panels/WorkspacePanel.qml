// panels/WorkspacePanel.qml
//
// The workspaces on this monitor, as a grid of tiles. Shown both by the bar's
// workspace dots and by the gesture dropdown's left zone.
//
// The design draws bare numbered tiles; each one also carries its window
// count, because a tile that only says "3" can't tell you whether there is
// anything on it — which is most of what an overview is for. Clicking a tile
// switches to that workspace.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../style"

Item {
    id: root

    required property ShellScreen screen

    // Part of the zone-panel contract in Dropdown.qml.
    readonly property bool wantsKeyboard: false

    // The other half of it: the height this panel's content wants, which the
    // owning surface clamps to the range it allows.
    readonly property int preferredHeight: Style.bar.padding * 2
        + header.height
        + Style.border.width
        + Style.bar.spacing
        + grid.height

    // Raised when something in here has been acted on, so the surface can get
    // out of the way instead of the panel reaching for shared state.
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

            // Tiles are sized from the panel rather than from the token, so
            // the grid fills whatever width the surface gives it; the token
            // is what the panel asks the surface *for*.
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
                    // Every tile is outlined, so the grid reads as a grid
                    // rather than as loose numbers; the active one brightens
                    // its outline instead of gaining one.
                    border.width: Style.border.width
                    border.color: tile.modelData.active ? Colors.workspaces.active : Colors.base.border

                    // Named workspaces exist — Hyprland's special ones are
                    // "special:magic" — and a name that long has to elide
                    // rather than run out of the tile and into its neighbour.
                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: Style.widgets.spacing
                            verticalCenter: parent.verticalCenter
                        }
                        // Centred in whatever the count leaves behind, the
                        // same way the popup rows derive their width from
                        // their siblings rather than from a magic number.
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

                    // The count, not the titles: at this tile size a title
                    // would elide to two characters and say nothing.
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
