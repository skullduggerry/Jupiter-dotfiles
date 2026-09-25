import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

// The monitor's workspaces, then what the desktop looks like: the wallpaper,
// whether it rotates, and the theme.
Item {
    id: root

    required property ShellScreen screen
    readonly property int preferredHeight: Style.bar.padding * 2 + header.height + Style.border.width + Style.bar.spacing + workspaceArea.height + Style.bar.spacing + Style.border.width + Style.bar.spacing + appearance.implicitHeight
    readonly property HyprlandMonitor monitor: root.screen ? Hyprland.monitorFor(root.screen) : null
    // The theme's own ANSI slots, as its card on the Themes page shows them;
    // the shell's accents until wallust has rendered a palette.
    readonly property var swatches: [Theme.palette.color1 || Colors.accent.red, Theme.palette.color2 || Colors.accent.green, Theme.palette.color3 || Colors.accent.yellow, Theme.palette.color4 || Colors.accent.blue, Theme.palette.color5 || Colors.accent.purple, Theme.palette.color6 || Colors.accent.cyan]
    readonly property var workspaces: {
        if (root.monitor === null)
            return [];

        return Hyprland.workspaces.values.filter((workspace) => {
            return workspace.monitor === root.monitor;
        }).sort((left, right) => {
            return left.id - right.id;
        });
    }

    signal activated()

    Item {
        anchors.fill: parent
        anchors.margins: Style.bar.padding

        Item {
            id: header

            height: Style.popup.itemHeight

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            Text {
                text: "Workspaces"
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

            }

            Text {
                text: root.monitor ? root.monitor.name : ""
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

            }

        }

        Rectangle {
            id: separator

            height: Style.border.width
            color: Colors.base.border

            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
            }

        }

        Grid {
            id: grid

            readonly property real tileWidth: (width - Style.workspaces.tileSpacing * (grid.columns - 1)) / grid.columns

            columns: Style.workspaces.tileColumns
            spacing: Style.workspaces.tileSpacing

            anchors {
                top: separator.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.bar.spacing
            }

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
                        id: tileName

                        // matching gutters keep the name centred in the tile whether
                        // or not the client count is showing
                        readonly property int gutter: Style.widgets.padding + (tileCount.visible ? tileCount.width + Style.widgets.spacing : 0)

                        text: tile.modelData.name
                        color: tile.modelData.active ? Colors.workspaces.active : tile.windowCount > 0 ? Colors.workspaces.occupied : Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.size
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter

                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: tileName.gutter
                            rightMargin: tileName.gutter
                            verticalCenter: parent.verticalCenter
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

        // Where the grid is, at least a row high, so the empty state has a
        // place of its own rather than the middle of the whole panel.
        Item {
            id: workspaceArea

            height: Math.max(Style.popup.itemHeight, grid.height)

            anchors {
                top: separator.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.bar.spacing
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
            id: appearanceSeparator

            height: Style.border.width
            color: Colors.base.border

            anchors {
                top: workspaceArea.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.bar.spacing
            }

        }

        Column {
            id: appearance

            spacing: Style.bar.spacing

            anchors {
                top: appearanceSeparator.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.bar.spacing
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

                Row {
                    spacing: Style.widgets.spacing

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }

                    PillButton {
                        compact: true
                        text: "Static"
                        checked: !WallpaperService.rotating
                        onClicked: WallpaperService.setRotating(false)
                    }

                    PillButton {
                        compact: true
                        text: "Rotate"
                        checked: WallpaperService.rotating
                        onClicked: WallpaperService.setRotating(true)
                    }

                }

            }

            // The current wallpaper as the app draws its cards.
            ClippingRectangle {
                width: parent.width
                height: width * Style.workspaces.previewRatio
                radius: Style.wallpaper.cardRadius
                color: Colors.base.hover

                Image {
                    anchors.fill: parent
                    source: WallpaperService.current !== "" ? "file://" + WallpaperService.current : ""
                    // As in WallpaperCard: a fixed decode width, which the
                    // pixmap cache can serve again the next time this opens.
                    sourceSize.width: Style.wallpaper.thumbnailWidth
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Rectangle {
                    visible: WallpaperService.currentName !== ""
                    width: Math.min(wallpaperName.implicitWidth + Style.wallpaper.labelPadding * 2, parent.width - Style.wallpaper.badgeInset * 2)
                    height: Style.wallpaper.labelHeight
                    radius: Style.wallpaper.labelRadius
                    color: Colors.overlay.scrim

                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        margins: Style.wallpaper.badgeInset
                    }

                    Text {
                        id: wallpaperName

                        anchors.fill: parent
                        anchors.leftMargin: Style.wallpaper.labelPadding
                        anchors.rightMargin: Style.wallpaper.labelPadding
                        text: WallpaperService.currentName
                        color: Colors.overlay.text
                        font.family: Style.text.font
                        font.pixelSize: Style.text.smallSize
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

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

        }

    }

}
