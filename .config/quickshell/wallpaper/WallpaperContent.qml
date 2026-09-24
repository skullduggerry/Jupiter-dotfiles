import "../style"
import QtQuick

FocusScope {
    id: root

    property int page: 0
    // The theme page runs palettes.py when it is built, so it waits until asked for.
    property bool themesOpened: false

    signal closeRequested()

    focus: true
    Keys.onEscapePressed: root.closeRequested()
    onPageChanged: {
        if (root.page === 1)
            themes.item.focusSearch();

    }

    Text {
        id: title

        text: "Wallpaper"
        color: Colors.text.base
        font.family: Style.text.font
        font.pixelSize: Style.text.largeSize
        font.weight: Font.Bold

        anchors {
            top: parent.top
            left: parent.left
            margins: Style.wallpaper.padding
        }

    }

    Row {
        id: tabs

        spacing: Style.bar.spacing

        anchors {
            top: title.bottom
            left: parent.left
            topMargin: Style.wallpaper.spacing
            leftMargin: Style.wallpaper.padding
        }

        PillButton {
            text: "Wallpapers"
            checked: root.page === 0
            onClicked: root.page = 0
        }

        PillButton {
            text: "Themes"
            checked: root.page === 1
            onClicked: {
                root.themesOpened = true;
                root.page = 1;
            }
        }

    }

    Item {
        id: pages

        anchors {
            top: tabs.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: Style.wallpaper.padding
            topMargin: Style.wallpaper.spacing
        }

        WallpaperPage {
            anchors.fill: parent
            visible: root.page === 0
        }

        Loader {
            id: themes

            anchors.fill: parent
            visible: root.page === 1
            // A hidden page keeps its focus, and the scope hands it back, so
            // only disabling it stops the search from taking keys on the other.
            enabled: root.page === 1
            active: root.themesOpened

            sourceComponent: ThemePage {
            }

        }

    }

}
