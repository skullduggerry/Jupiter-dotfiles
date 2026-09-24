import "../panels"
import "../services"
import "../style"
import QtQuick
import Quickshell.Io

// Every wallust theme, and whether one applies to the apps too (kitty, nvim,
// and Qt/KDE apps through kdeglobals and Kvantum) or to the shell alone.
Item {
    id: root

    // config/wallust/palettes.py's catalogue: the themes in colorschemes/
    // first, then wallust's built-ins.
    property var themes: []
    readonly property var shown: {
        const query = search.text.trim().toLowerCase();
        return query === "" ? root.themes : root.themes.filter((theme) => {
            return theme.name.toLowerCase().includes(query);
        });
    }
    readonly property int columns: Math.max(1, Math.floor((root.width + Style.wallpaper.spacing) / (Style.wallpaper.themeCardWidth + Style.wallpaper.spacing)))

    function focusSearch() {
        search.focusInput();
    }

    Component.onCompleted: catalogue.running = true

    // A theme just generated from a wallpaper is new to the catalogue.
    Connections {
        function onThemeChanged() {
            if (!root.themes.some((theme) => {
                return theme.name === Theme.theme;
            }))
                catalogue.running = true;

        }

        target: Theme
    }

    Process {
        id: catalogue

        command: ["python3", Theme.scripts + "/palettes.py"]

        stdout: StdioCollector {
            id: output

            onStreamFinished: {
                try {
                    root.themes = JSON.parse(output.text);
                } catch (error) {
                    console.warn("themes: palettes.py printed no catalogue:", error);
                    return ;
                }
                const applied = root.themes.findIndex((theme) => {
                    return theme.name === Theme.theme;
                });
                // Once the view has laid the new model out.
                if (applied >= 0)
                    Qt.callLater(() => {
                    return grid.positionViewAtIndex(applied, GridView.Contain);
                });

            }
        }

    }

    InputField {
        id: search

        width: Style.wallpaper.searchWidth
        placeholder: "Search themes"
        icon: "\u{F0349}"
    }

    GridView {
        id: grid

        // As in WallpaperPage: one spacing wider, so the last column is flush.
        width: root.width + Style.wallpaper.spacing
        cellWidth: grid.width / root.columns
        cellHeight: Style.wallpaper.themeCardHeight + Style.wallpaper.spacing
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.shown

        anchors {
            top: search.bottom
            topMargin: Style.wallpaper.spacing
            bottom: footer.top
            bottomMargin: Style.wallpaper.spacing
            left: parent.left
        }

        delegate: ThemeCard {
            width: grid.cellWidth - Style.wallpaper.spacing
            height: grid.cellHeight - Style.wallpaper.spacing
        }

    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: grid.verticalCenter
        visible: grid.count === 0
        text: {
            if (catalogue.running)
                return "Loading themes…";

            return root.themes.length === 0 ? "Could not list wallust's themes" : "No theme matches";
        }
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
                text: "APPLY TO"
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
                font.weight: Font.Medium
            }

            PillButton {
                text: "Shell"
                checked: !Theme.applyToApps
                onClicked: Theme.setApplyToApps(false)
            }

            PillButton {
                text: "Shell and apps"
                checked: Theme.applyToApps
                onClicked: Theme.setApplyToApps(true)
            }

        }

        Row {
            spacing: Style.bar.spacing
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.error !== "" ? Theme.error : Theme.applying ? "Applying…" : ""
                color: Theme.error !== "" ? Colors.status.error : Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
            }

            PillButton {
                text: "New from wallpaper"
                action: true
                visible: WallpaperService.current !== ""
                onClicked: Theme.generate(WallpaperService.current)
            }

        }

    }

}
