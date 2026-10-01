pragma ComponentBehavior: Bound

import "../icons"
import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland

// The monitor's workspaces, then what the desktop looks like: the wallpaper,
// which leads to its settings, whether it rotates, and the theme; then the
// keyboard layouts.
PanelFrame {
    id: root

    required property ShellScreen screen
    implicitHeight: root.chromeHeight + sections.implicitHeight
    readonly property HyprlandMonitor monitor: root.screen ? Hyprland.monitorFor(root.screen) : null
    readonly property string monitorName: root.monitor ? root.monitor.name : ""
    // The theme's own ANSI slots, as its card on the Themes page shows them;
    // the shell's accents until wallust has rendered a palette.
    readonly property list<color> swatches: [Theme.palette.color1 || Colors.accent.red, Theme.palette.color2 || Colors.accent.green, Theme.palette.color3 || Colors.accent.yellow, Theme.palette.color4 || Colors.accent.blue, Theme.palette.color5 || Colors.accent.purple, Theme.palette.color6 || Colors.accent.cyan]
    // This monitor's own workspaces, then any it holds for one unplugged.
    readonly property var workspaces: Hyprland.workspaces.values.filter(workspace => root.monitor !== null && workspace.monitor === root.monitor).sort((left, right) => WorkspaceBlocks.parked(left, root.monitorName) - WorkspaceBlocks.parked(right, root.monitorName) || left.id - right.id)

    signal activated

    // The number the keys go by; a special workspace keeps its name.
    function label(workspace: HyprlandWorkspace): string {
        if (workspace.id <= 0)
            return workspace.name;

        return WorkspaceBlocks.number(workspace);
    }

    title: "Workspaces"

    Column {
        id: sections

        width: parent.width
        spacing: Style.bar.spacing

        // At least a row high, so the empty state has a place of its own.
        Item {
            width: parent.width
            height: Math.max(Style.popup.itemHeight, grid.height)

            Grid {
                id: grid

                readonly property real tileWidth: (width - Style.workspaces.tileSpacing * (grid.columns - 1)) / grid.columns

                width: parent.width
                columns: Style.workspaces.tileColumns
                spacing: Style.workspaces.tileSpacing

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

                        // The name, marked when the workspace only waits here.
                        // Matching gutters keep it centred whether or not the
                        // window count shows.
                        Row {
                            id: tileName

                            readonly property int gutter: Style.widgets.padding + (tileCount.visible ? tileCount.width + Style.widgets.spacing : 0)
                            readonly property color colour: tile.modelData.active ? Colors.workspaces.active : tile.windowCount > 0 ? Colors.workspaces.occupied : Colors.text.muted

                            anchors.centerIn: parent
                            spacing: Style.widgets.spacing

                            Icon {
                                id: parkedMark

                                visible: tile.modelData.id > 0 && WorkspaceBlocks.parked(tile.modelData, root.monitorName)
                                anchors.verticalCenter: parent.verticalCenter
                                text: Icons.monitorOff
                                color: tileName.colour
                                font.pixelSize: Style.text.size
                            }

                            Text {
                                width: Math.min(implicitWidth, tile.width - tileName.gutter * 2 - (parkedMark.visible ? parkedMark.width + tileName.spacing : 0))
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.label(tile.modelData)
                                color: tileName.colour
                                font.family: Style.text.font
                                font.pixelSize: Style.text.size
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            id: tileCount

                            visible: tile.windowCount > 0
                            text: tile.windowCount
                            color: Colors.text.muted
                            font.family: Style.text.font
                            font.pixelSize: Style.text.smallSize

                            anchors {
                                right: parent.right
                                rightMargin: Style.widgets.padding
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: tileArea

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                tile.modelData.activate();
                                root.activated();
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

        Rectangle {
            width: parent.width
            height: Style.border.width
            color: Colors.base.border
        }

        Item {
            width: parent.width
            height: Style.popup.itemHeight

            Text {
                id: wallpaperTitle

                text: "Wallpaper"
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }

            Text {
                visible: WallpaperService.rotating
                text: "every " + WallpaperService.rotateLabel(WallpaperService.rotateMinutes)
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize

                anchors {
                    left: wallpaperTitle.right
                    leftMargin: Style.bar.spacing
                    verticalCenter: parent.verticalCenter
                }
            }

            PillGroup {
                compact: true
                choices: WallpaperService.modeChoices
                current: WallpaperService.rotating
                onPicked: rotating => WallpaperService.setRotating(rotating)

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        WallpaperCard {
            width: parent.width
            height: width * Style.workspaces.previewRatio
            filePath: WallpaperService.current
            fileUrl: WallpaperService.current !== "" ? "file://" + WallpaperService.current : ""
            fileBaseName: WallpaperService.currentName
            onClicked: {
                root.activated();
                SettingsState.show("wallpaper");
            }
        }

        Item {
            width: parent.width
            height: Style.popup.itemHeight

            Text {
                text: "Theme"
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }

            Row {
                spacing: Style.bar.spacing

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.widgets.spacing

                    Repeater {
                        model: root.swatches

                        delegate: Rectangle {
                            id: swatch

                            required property color modelData

                            width: Style.wallpaper.swatchSize
                            height: Style.wallpaper.swatchSize
                            radius: width / 2
                            color: swatch.modelData
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.theme
                    color: Colors.text.base
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                }
            }
        }

        // The keyboard layouts, once there are several: the one in use by
        // name, and a pill for each, as the bar's keyboard switches them.
        Column {
            visible: KeyboardLayout.layouts.length > 1
            width: parent.width
            spacing: Style.bar.spacing

            Rectangle {
                width: parent.width
                height: Style.border.width
                color: Colors.base.border
            }

            Item {
                width: parent.width
                height: Style.popup.itemHeight

                Text {
                    id: keyboardTitle

                    text: "Keyboard"
                    color: Colors.text.base
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size

                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    text: KeyboardLayout.name
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                    elide: Text.ElideRight

                    anchors {
                        left: keyboardTitle.right
                        right: layouts.left
                        leftMargin: Style.bar.spacing
                        rightMargin: Style.bar.spacing
                        verticalCenter: parent.verticalCenter
                    }
                }

                PillGroup {
                    id: layouts

                    compact: true
                    choices: KeyboardLayout.layouts.map((label, index) => ({
                                label: label,
                                value: index
                            }))
                    current: KeyboardLayout.index
                    onPicked: index => KeyboardLayout.select(index)

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    // Which monitor's workspaces these are, once there are several, since each
    // numbers its own from 1: the layout, this one filled in, and its name.
    trailing: Row {
        visible: Quickshell.screens.length > 1
        spacing: Style.widgets.spacing

        Item {
            id: monitorMap

            readonly property rect bounds: {
                let left = Infinity;
                let top = Infinity;
                let right = -Infinity;
                let bottom = -Infinity;
                for (const output of Quickshell.screens) {
                    left = Math.min(left, output.x);
                    top = Math.min(top, output.y);
                    right = Math.max(right, output.x + output.width);
                    bottom = Math.max(bottom, output.y + output.height);
                }
                return Qt.rect(left, top, right - left, bottom - top);
            }
            readonly property real unit: Style.workspaces.mapHeight / monitorMap.bounds.height

            anchors.verticalCenter: parent.verticalCenter
            width: monitorMap.bounds.width * monitorMap.unit
            height: Style.workspaces.mapHeight

            Repeater {
                model: Quickshell.screens

                delegate: Rectangle {
                    id: output

                    required property ShellScreen modelData

                    x: (output.modelData.x - monitorMap.bounds.x) * monitorMap.unit
                    y: (output.modelData.y - monitorMap.bounds.y) * monitorMap.unit
                    width: output.modelData.width * monitorMap.unit - Style.workspaces.mapGap
                    height: output.modelData.height * monitorMap.unit - Style.workspaces.mapGap
                    radius: Style.workspaces.mapRadius
                    color: output.modelData === root.screen ? Colors.workspaces.active : Colors.workspaces.inactive
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.monitorName
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
        }
    }
}
