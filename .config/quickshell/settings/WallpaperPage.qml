import "../panels"
import "../style"
import QtQuick

// The design's wallpaper selector and, beside it, every wallust theme. The
// theme grid runs palettes.py when it is built, so it waits until asked for.
FocusScope {
    id: root

    property int tab: 0
    property bool themesOpened: false

    focus: true
    onTabChanged: {
        if (root.tab === 1)
            (themes.item as ThemeGrid).focusSearch();
    }

    PillGroup {
        id: tabs

        choices: [
            {
                label: "Wallpapers",
                value: 0
            },
            {
                label: "Themes",
                value: 1
            }
        ]
        current: root.tab
        onPicked: tab => {
            root.themesOpened = root.themesOpened || tab === 1;
            root.tab = tab;
        }

        anchors {
            top: parent.top
            left: parent.left
            leftMargin: Style.settings.padding
        }
    }

    Item {
        anchors {
            top: tabs.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: Style.settings.padding
            topMargin: Style.settings.spacing
        }

        WallpaperGrid {
            anchors.fill: parent
            visible: root.tab === 0
        }

        Loader {
            id: themes

            anchors.fill: parent
            visible: root.tab === 1
            // A hidden page keeps its focus, and the scope hands it back, so
            // only disabling it stops the search from taking keys on the other.
            enabled: root.tab === 1
            active: root.themesOpened

            sourceComponent: ThemeGrid {}
        }
    }
}
