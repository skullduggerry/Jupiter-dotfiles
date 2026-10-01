import "../panels"
import "../services"
import "../style"
import QtQuick

// The design's Appearance page, its wallpaper selector and every wallust
// theme, a tab each. The tab shown is SettingsState.page, so SUPER+W and
// `openPage wallpaper` or `themes` open on theirs; SettingsContent lists these
// names as the page's `tabs` for that.
FocusScope {
    id: root

    // "appearance", or a name that is no tab, is the Style tab.
    readonly property string tab: tabs.choices.some(choice => choice.value === SettingsState.page) ? SettingsState.page : "appearance"
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

    PillGroup {
        id: tabs

        choices: [
            {
                label: "Style",
                value: "appearance"
            },
            {
                label: "Wallpapers",
                value: "wallpaper"
            },
            {
                label: "Themes",
                value: "themes"
            }
        ]
        current: root.tab
        onPicked: tab => SettingsState.page = tab

        anchors {
            top: parent.top
            left: parent.left
            leftMargin: Style.settings.padding
        }
    }

    // A hidden tab keeps its focus, and the scope hands it back, so only
    // disabling it stops a field on it (the font list, the theme search) from
    // taking keys on another.
    Item {
        anchors {
            top: tabs.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: Style.settings.padding
            topMargin: Style.settings.spacing
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
}
