pragma ComponentBehavior: Bound

import "../icons"
import "../panels"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Hyprland's binds as it has them loaded (`hyprctl binds`), named by the
// descriptions config/hypr/modules/keybinds.lua gives them: Lua binds report
// no more than a callback number. Binds sharing a description and modifiers
// are one row (SUPER + 1–9), and a config reload reads them again.
Item {
    id: root

    readonly property int columnWidth: Math.min(Style.settings.listWidth, root.width - Style.settings.padding * 2)
    readonly property string keybindsFile: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/hypr/modules/keybinds.lua"
    property var rows: []
    readonly property var shown: {
        const query = search.text.trim().toLowerCase();
        return query === "" ? root.rows : root.rows.filter(row => row.description.toLowerCase().includes(query) || row.keys.join(" ").toLowerCase().includes(query));
    }

    // Modifier bits as Hyprland counts them, in the order they are written.
    function modifierNames(mask) {
        const bits = {
            SUPER: 64,
            CTRL: 4,
            ALT: 8,
            SHIFT: 1
        };
        return Object.keys(bits).filter(name => (mask & bits[name]) !== 0);
    }

    function keyName(key: string): string {
        const names = {
            left: "←",
            right: "→",
            up: "↑",
            down: "↓",
            PRINT: "Print",
            Return: "Enter",
            space: "Space",
            Escape: "Esc",
            XF86AudioRaiseVolume: "Volume Up",
            XF86AudioLowerVolume: "Volume Down",
            XF86AudioMute: "Mute",
            XF86MonBrightnessUp: "Brightness Up",
            XF86MonBrightnessDown: "Brightness Down"
        };
        if (key in names)
            return names[key];

        if (key.startsWith("XF86"))
            return key.slice(4).replace(/([a-z])([A-Z])/g, "$1 $2");

        return key.length === 1 ? key.toUpperCase() : key.charAt(0).toUpperCase() + key.slice(1);
    }

    // The keys of a merged row: a run of digits as a range, anything else side by side.
    function keysLabel(keys): string {
        if (keys.length > 2 && keys.every((key, index) => /^[0-9]$/.test(key) && (index === 0 || Number(key) === Number(keys[index - 1]) + 1)))
            return keys[0] + "–" + keys[keys.length - 1];

        return keys.map(root.keyName).join(" ");
    }

    function load(binds) {
        const merged = [];
        const byName = {};
        for (const bind of binds) {
            const description = bind.has_description ? bind.description : "";
            const name = description + "\n" + bind.modmask + "\n" + bind.submap;
            if (description !== "" && name in byName) {
                byName[name].keys.push(bind.key);
                continue;
            }
            const row = {
                description: description,
                modifiers: root.modifierNames(bind.modmask),
                keys: [bind.key]
            };
            merged.push(row);
            if (description !== "")
                byName[name] = row;
        }
        root.rows = merged;
    }

    Component.onCompleted: reader.running = true

    Connections {
        function onRawEvent(event: HyprlandEvent) {
            if (event.name === "configreloaded")
                reader.running = true;
        }

        target: Hyprland
    }

    Process {
        id: reader

        command: ["hyprctl", "binds", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.load(JSON.parse(text));
                } catch (error) {
                    console.warn("keybinds: hyprctl printed no binds:", error);
                }
            }
        }
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

            delegate: Item {
                id: row

                required property var modelData

                width: list.width
                height: Style.settings.itemHeight

                Text {
                    text: row.modelData.description !== "" ? row.modelData.description : "No description"
                    color: row.modelData.description !== "" ? Colors.text.base : Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size
                    elide: Text.ElideRight

                    anchors {
                        left: parent.left
                        right: keys.left
                        rightMargin: Style.bar.spacing
                        verticalCenter: parent.verticalCenter
                    }
                }

                Row {
                    id: keys

                    spacing: Style.widgets.spacing

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }

                    Repeater {
                        model: row.modelData.modifiers.concat([root.keysLabel(row.modelData.keys)])

                        delegate: KeyCap {}
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: list.count === 0
            text: root.rows.length === 0 ? "Reading Hyprland's binds…" : "No keybind matches"
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
