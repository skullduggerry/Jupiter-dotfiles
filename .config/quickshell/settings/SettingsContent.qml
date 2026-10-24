pragma ComponentBehavior: Bound

import "../icons"
import "../panels"
import "../services"
import "../style"
import QtQuick

// The Figma file's "Settings" frame: a sidebar with a search field and one
// entry per page, and the page. The design draws Appearance; the rest follow it.
FocusScope {
    id: root

    // Searched by title and by these words. A page with tabs has its words on
    // them, the first tab being the page itself, and shows them as pills;
    // SettingsState.page may name any of them, opening the page on that tab.
    readonly property var pages: [
        {
            name: "appearance",
            title: "Appearance",
            icon: Icons.palette,
            tabs: [
                {
                    name: "appearance",
                    title: "Style",
                    keywords: "theme light dark accent colour colours color colors font blur strength tint glass solid panels dropdowns"
                },
                {
                    name: "wallpaper",
                    title: "Wallpapers",
                    keywords: "wallpaper background rotate image workspace"
                },
                {
                    name: "themes",
                    title: "Themes",
                    keywords: "theme themes"
                },
                {
                    name: "lockscreen",
                    title: "Lock Screen",
                    keywords: "lock screen login greeter sign in background wallpaper image plain blur dim darkness clock password"
                }
            ]
        },
        {
            name: "displays",
            title: "Displays",
            icon: Icons.monitor,
            keywords: "monitor screen brightness night light warmth scale resolution refresh rate rotation arrangement adaptive sync vrr bar main small bars"
        },
        {
            name: "sound",
            title: "Sound",
            icon: Icons.volume2,
            keywords: "audio volume speaker headphones microphone output input device mute apps"
        },
        {
            name: "network",
            title: "Network & Bluetooth",
            icon: Icons.wifi,
            tabs: [
                {
                    name: "network",
                    title: "Network",
                    keywords: "wifi wi-fi wireless internet ip address dns gateway"
                },
                {
                    name: "bluetooth",
                    title: "Bluetooth",
                    keywords: "devices pair unpair forget connect headphones speaker visible discoverable"
                }
            ]
        },
        {
            name: "notifications",
            title: "Notifications",
            icon: Icons.bell,
            keywords: "do not disturb dnd alerts"
        },
        {
            name: "power",
            title: "Power",
            icon: Icons.power,
            keywords: "battery power mode profile saver performance balanced idle lock suspend sleep screen off timeout"
        },
        {
            name: "keyboard",
            title: "Keyboard",
            icon: Icons.keyboard,
            tabs: [
                {
                    name: "keyboard",
                    title: "Layouts",
                    keywords: "keyboard layout layouts language input source variant us de qwerty qwertz azerty dvorak caps lock quick menu"
                },
                {
                    name: "keybinds",
                    title: "Keybinds",
                    keywords: "keyboard shortcuts keys hotkeys binds"
                }
            ]
        },
        {
            name: "tablet",
            title: "Tablet",
            icon: Icons.penTool,
            keywords: "drawing tablet wacom pen stylus pressure sensitivity area screen window proportions left handed expresskeys pad buttons keys"
        },
        {
            name: "about",
            title: "About",
            icon: Icons.info,
            tabs: [
                {
                    name: "about",
                    title: "System",
                    keywords: "system info version cpu memory kernel hostname"
                },
                {
                    name: "startup",
                    title: "Startup",
                    keywords: "autostart login apps session launch boot"
                }
            ]
        }
    ]
    readonly property string query: search.text.trim().toLowerCase()
    readonly property var shown: root.query === "" ? root.pages : root.pages.filter(page => root.matches(page) || (page.tabs ?? []).some(tab => root.matches(tab)))
    readonly property var current: root.pages.find(page => page.name === SettingsState.page || (page.tabs ?? []).some(tab => tab.name === SettingsState.page)) || root.pages[0]
    // SettingsState.page where it is one of the page's tabs, else the page's
    // own name, its first tab's.
    readonly property string tab: (root.current.tabs ?? []).some(tab => tab.name === SettingsState.page) ? SettingsState.page : root.current.name

    signal closeRequested

    // Keeps the tab of the page already shown.
    function openPage(page) {
        if (page.name !== root.current.name)
            SettingsState.page = page.name;
    }

    function matches(entry): bool {
        return entry.title.toLowerCase().includes(root.query) || (entry.keywords ?? "").includes(root.query);
    }

    focus: true
    Keys.onEscapePressed: root.closeRequested()

    Item {
        id: sidebar

        width: Style.settings.sidebarWidth

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }

        Text {
            id: title

            text: "Settings"
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.largeSize
            font.weight: Font.Bold

            anchors {
                top: parent.top
                left: parent.left
                margins: Style.settings.padding
            }
        }

        InputField {
            id: search

            placeholder: "Search settings…"
            icon: Icons.search
            // Enter opens the first page that matches, on the first of its
            // tabs that does.
            onAccepted: {
                const page = root.shown[0];
                if (page === undefined)
                    return;

                const tab = (page.tabs ?? []).find(tab => root.matches(tab));
                if (tab !== undefined)
                    SettingsState.page = tab.name;
                else
                    root.openPage(page);
            }

            anchors {
                top: title.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.settings.spacing
                leftMargin: Style.settings.padding
                rightMargin: Style.settings.padding
            }
        }

        ListView {
            id: entries

            clip: true
            spacing: Style.widgets.spacing
            boundsBehavior: Flickable.StopAtBounds
            model: root.shown

            anchors {
                top: search.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.settings.spacing
                leftMargin: Style.bar.spacing
                rightMargin: Style.bar.spacing
                bottomMargin: Style.settings.padding
            }

            delegate: Rectangle {
                id: entry

                required property var modelData
                readonly property bool selected: entry.modelData.name === root.current.name

                width: entries.width
                height: Style.settings.itemHeight
                radius: Style.settings.itemRadius
                color: entry.selected || entryArea.containsMouse ? Colors.base.hover : "transparent"

                Icon {
                    id: entryIcon

                    width: Style.settings.iconWidth
                    text: entry.modelData.icon
                    font.pixelSize: Style.text.size

                    anchors {
                        left: parent.left
                        leftMargin: Style.settings.padding - Style.bar.spacing
                        verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    text: entry.modelData.title
                    color: entry.selected ? Colors.text.base : Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size
                    font.weight: entry.selected ? Font.Medium : Font.Normal
                    elide: Text.ElideRight

                    anchors {
                        left: entryIcon.right
                        right: parent.right
                        leftMargin: Style.bar.spacing
                        rightMargin: Style.bar.spacing
                        verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: entryArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openPage(entry.modelData)
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Style.animation.normal
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: entries.horizontalCenter
            anchors.top: entries.top
            visible: entries.count === 0
            text: "No setting matches"
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }
    }

    Rectangle {
        id: divider

        width: Style.border.width
        color: Colors.base.border

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: sidebar.right
            topMargin: Style.settings.padding
            bottomMargin: Style.settings.padding
        }
    }

    Item {
        id: page

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: divider.right
            right: parent.right
        }

        Text {
            id: pageTitle

            text: root.current.title
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.largeSize
            font.weight: Font.Bold

            anchors {
                top: parent.top
                left: parent.left
                margins: Style.settings.padding
            }
        }

        PillGroup {
            id: tabs

            visible: root.current.tabs !== undefined
            choices: (root.current.tabs ?? []).map(tab => ({
                        label: tab.title,
                        value: tab.name
                    }))
            current: root.tab
            onPicked: tab => SettingsState.page = tab

            anchors {
                top: pageTitle.bottom
                left: parent.left
                topMargin: Style.settings.spacing
                leftMargin: Style.settings.padding
            }
        }

        // A page is built while it is shown and no longer, and so is each tab
        // but Appearance's, which keeps its own: Network scans for Wi-Fi,
        // Bluetooth searches for devices, About reads the CPU every second.
        Loader {
            id: body

            focus: true
            sourceComponent: {
                switch (root.tab) {
                case "displays":
                    return displaysPage;
                case "sound":
                    return soundPage;
                case "network":
                    return networkPage;
                case "bluetooth":
                    return bluetoothPage;
                case "notifications":
                    return notificationsPage;
                case "power":
                    return powerPage;
                case "keyboard":
                    return keyboardPage;
                case "keybinds":
                    return keybindsPage;
                case "tablet":
                    return tabletPage;
                case "startup":
                    return startupPage;
                case "about":
                    return aboutPage;
                default:
                    return appearancePage;
                }
            }

            anchors {
                top: tabs.visible ? tabs.bottom : pageTitle.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.settings.spacing
            }
        }
    }

    Component {
        id: appearancePage

        AppearancePage {
            tab: root.tab
        }
    }

    Component {
        id: displaysPage

        DisplaysPage {}
    }

    Component {
        id: soundPage

        SoundPage {}
    }

    Component {
        id: networkPage

        NetworkPage {}
    }

    Component {
        id: bluetoothPage

        BluetoothPage {}
    }

    Component {
        id: notificationsPage

        NotificationsPage {}
    }

    Component {
        id: powerPage

        PowerPage {}
    }

    Component {
        id: keyboardPage

        KeyboardPage {}
    }

    Component {
        id: keybindsPage

        KeybindsPage {}
    }

    Component {
        id: tabletPage

        TabletPage {}
    }

    Component {
        id: startupPage

        StartupPage {}
    }

    Component {
        id: aboutPage

        AboutPage {}
    }
}
