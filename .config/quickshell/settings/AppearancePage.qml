import "../style"
import QtQuick

// The design's Appearance page, its wallpaper selector, every wallust theme
// and the lock and login screens, a tab each. SettingsContent draws the tabs
// and passes the one shown, SettingsState.page itself, so SUPER+W and
// `openPage wallpaper`, `themes` or `lockscreen` open on theirs.
FocusScope {
    id: root

    // "appearance" is the Style tab.
    required property string tab
    // The wallpaper thumbnails decode and palettes.py runs when their tab is
    // built, so each waits until it is first shown, and then stays.
    property bool wallpapersOpened: false
    property bool themesOpened: false

    function showTab() {
        root.wallpapersOpened = root.wallpapersOpened || root.tab === "wallpaper";
        root.themesOpened = root.themesOpened || root.tab === "themes";
        // A page opened on this tab runs this before the grid is built; the
        // grid's Loader focuses it once it is.
        if (root.tab === "themes")
            (themes.item as ThemeGrid)?.focusSearch();
    }

    focus: true
    onTabChanged: root.showTab()
    Component.onCompleted: root.showTab()

    // A hidden tab keeps its focus, and the scope hands it back, so only
    // disabling it stops a field on it (the font list, the theme search) from
    // taking keys on another.
    Item {
        anchors {
            fill: parent
            leftMargin: Style.settings.padding
            rightMargin: Style.settings.padding
            bottomMargin: Style.settings.padding
        }

        StyleOptions {
            visible: root.tab === "appearance"
            enabled: root.tab === "appearance"
        }

        Loader {
            anchors.fill: parent
            visible: root.tab === "wallpaper"
            enabled: root.tab === "wallpaper"
            active: root.wallpapersOpened

            sourceComponent: WallpaperGrid {}
        }

        Loader {
            id: themes

            anchors.fill: parent
            visible: root.tab === "themes"
            enabled: root.tab === "themes"
            active: root.themesOpened
            onLoaded: {
                if (root.tab === "themes")
                    (themes.item as ThemeGrid).focusSearch();
            }

            sourceComponent: ThemeGrid {}
        }
    }

    // Built while it is shown, as a page is.
    Loader {
        anchors.fill: parent
        active: root.tab === "lockscreen"

        sourceComponent: LockPage {}
    }
}
