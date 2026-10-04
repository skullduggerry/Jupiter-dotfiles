pragma ComponentBehavior: Bound

import "../icons"
import "../panels"
import "../services"
import "../style"
import QtQuick
import Quickshell

// Hyprland's binds (services/Keybinds), searchable; the shortcuts overlay
// shows them over the desktop, with a keyboard.
Item {
    id: root

    readonly property int columnWidth: Math.min(Style.settings.listWidth, root.width - Style.settings.padding * 2)
    readonly property string keybindsFile: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/hypr/modules/keybinds.lua"
    readonly property var shown: {
        const query = search.text.trim().toLowerCase();
        return query === "" ? Keybinds.rows : Keybinds.rows.filter(row => row.description.toLowerCase().includes(query) || row.keys.join(" ").toLowerCase().includes(query));
    }

    InputField {
        id: search

        width: Math.min(Style.settings.fieldWidth * 2, root.columnWidth)
        placeholder: "Search keybinds…"
        icon: Icons.search

        anchors {
            top: parent.top
            left: parent.left
            leftMargin: Style.settings.padding
        }
    }

    Card {
        id: card

        width: root.columnWidth

        anchors {
            top: search.bottom
            bottom: footer.top
            left: parent.left
            topMargin: Style.settings.spacing
            bottomMargin: Style.settings.spacing
            leftMargin: Style.settings.padding
        }

        ListView {
            id: list

            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.shown

            anchors {
                fill: parent
                margins: Style.bar.padding
            }

            delegate: KeybindRow {
                width: list.width
                height: Style.settings.itemHeight
            }
        }

        Text {
            anchors.centerIn: parent
            visible: list.count === 0
            text: Keybinds.rows.length === 0 ? "Reading Hyprland's binds…" : "No keybind matches"
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }
    }

    ActionRow {
        id: footer

        width: root.columnWidth
        text: "As Hyprland has them, described in keybinds.lua"
        action: "Edit keybinds.lua"
        onActivated: Quickshell.execDetached(["xdg-open", root.keybindsFile])

        anchors {
            bottom: parent.bottom
            left: parent.left
            leftMargin: Style.settings.padding
            bottomMargin: Style.settings.padding
        }
    }
}
