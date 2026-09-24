import "../services"
import "../style"
import Qt.labs.folderlistmodel
import QtQuick

// ~/Wallpapers as a grid, and the panels' Blur/Solid switch beside it: a light
// wallpaper is what makes the translucent bar hard to read.
Item {
    id: root

    readonly property int columns: Math.max(1, Math.floor((root.width + Style.wallpaper.spacing) / (Style.wallpaper.cardWidth + Style.wallpaper.spacing)))

    GridView {
        id: grid

        // One spacing wider than the page, so every cell can carry its gap on
        // the right and the last column still ends flush with the page.
        width: root.width + Style.wallpaper.spacing
        cellWidth: grid.width / root.columns
        cellHeight: (grid.cellWidth - Style.wallpaper.spacing) * Style.wallpaper.cardRatio + Style.wallpaper.spacing
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        anchors {
            top: parent.top
            bottom: footer.top
            bottomMargin: Style.wallpaper.spacing
            left: parent.left
        }

        // Watches the directory, so "Add from file…" shows up by itself.
        model: FolderListModel {
            folder: "file://" + WallpaperService.directory
            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp"]
            caseSensitive: false
            showDirs: false
            sortCaseSensitive: false
        }

        delegate: WallpaperCard {
            width: grid.cellWidth - Style.wallpaper.spacing
            height: grid.cellHeight - Style.wallpaper.spacing
        }

    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: grid.verticalCenter
        visible: grid.count === 0
        text: "No wallpapers in ~/Wallpapers yet"
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

        Row {
            spacing: Style.bar.spacing
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "PANELS"
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
                font.weight: Font.Medium
            }

            PillButton {
                text: "Blur"
                checked: Theme.blur
                onClicked: Theme.setBlur(true)
            }

            PillButton {
                text: "Solid"
                checked: !Theme.blur
                onClicked: Theme.setBlur(false)
            }

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
