pragma ComponentBehavior: Bound

import "../panels"
import "../services"
import "../style"
import QtQuick

// ~/Wallpapers under the wallpaper mode and, once it has subfolders, a tab for
// each; below, where a pick goes.
Item {
    id: root

    readonly property int columns: Math.max(1, Math.floor((root.width + Style.settings.spacing) / (Style.wallpaper.cardWidth + Style.settings.spacing)))

    // Where the theme grid has its search field, so both grids start level.
    Row {
        id: mode

        spacing: Style.settings.spacing

        PillGroup {
            label: "MODE"
            choices: WallpaperService.modeChoices
            current: WallpaperService.rotating
            onPicked: rotating => WallpaperService.setRotating(rotating)
        }

        PillGroup {
            visible: WallpaperService.rotating
            label: "EVERY"
            choices: WallpaperService.rotateChoices.map(minutes => ({
                        label: WallpaperService.rotateLabel(minutes),
                        value: minutes
                    }))
            current: WallpaperService.rotateMinutes
            onPicked: minutes => WallpaperService.setRotateMinutes(minutes)
        }
    }

    // The design's category tabs; "All" is the top folder and every subfolder.
    PillGroup {
        id: categories

        visible: WallpaperService.categoryNames.length > 0
        choices: [""].concat(WallpaperService.categoryNames).map(name => ({
                    label: name === "" ? "All" : name,
                    value: name
                }))
        current: WallpaperService.category
        onPicked: name => WallpaperService.setCategory(name)

        anchors {
            top: mode.bottom
            left: parent.left
            right: parent.right
            topMargin: Style.settings.spacing
        }
    }

    GridView {
        id: grid

        // One spacing wider than the page, so every cell can carry its gap on
        // the right and the last column still ends flush with the page.
        width: root.width + Style.settings.spacing
        cellWidth: grid.width / root.columns
        cellHeight: (grid.cellWidth - Style.settings.spacing) * Style.wallpaper.cardRatio + Style.settings.spacing
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: WallpaperService.library

        anchors {
            top: categories.visible ? categories.bottom : mode.bottom
            topMargin: Style.settings.spacing
            bottom: footer.top
            bottomMargin: Style.settings.spacing
            left: parent.left
        }

        delegate: WallpaperCard {
            id: card

            width: grid.cellWidth - Style.settings.spacing
            height: grid.cellHeight - Style.settings.spacing
            onClicked: WallpaperService.apply(card.filePath)
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: grid.verticalCenter
        visible: grid.count === 0
        text: "No wallpapers in " + (WallpaperService.category === "" ? "~/Wallpapers" : WallpaperService.category) + " yet"
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.size
    }

    Item {
        id: footer

        height: Style.popup.itemHeight

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        // hyprpaper sets a monitor, not a workspace: a workspace's own is put
        // on its monitor whenever the workspace is shown there.
        PillGroup {
            anchors.verticalCenter: parent.verticalCenter
            label: "APPLY TO"
            choices: [
                {
                    label: "This Workspace",
                    value: "workspace"
                },
                {
                    label: "All Workspaces",
                    value: "all"
                }
            ]
            current: WallpaperService.target
            onPicked: target => WallpaperService.setTarget(target)
        }

        Row {
            spacing: Style.bar.spacing
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: WallpaperService.error
                color: Colors.status.error
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
            }

            PillButton {
                text: "Add from file…"
                action: true
                onClicked: WallpaperService.importFile()
            }
        }
    }
}
