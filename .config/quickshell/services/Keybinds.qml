pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Hyprland's binds as it has them loaded (`hyprctl binds`), named by the
// descriptions config/hypr/modules/keybinds.lua gives them: Lua binds report
// no more than a callback number. Binds sharing a description and modifiers
// are one row (SUPER + 1–9), and a config reload reads them again. The
// Settings app's Keybinds page and the shortcuts overlay show them.
Singleton {
    id: root

    // {index, description, modifiers: ["SUPER"], keys: ["Q"]}, in the config's
    // order; a bind on a keycode has "code:N" for its key. A view's delegates
    // get copies of a row, so `index` is what tells which one they have.
    property var rows: []
    // Modifier bits as Hyprland counts them, in the order they are written,
    // and the key each is (the left one).
    readonly property var modifiers: [
        {
            name: "SUPER",
            bit: 64,
            key: "Super_L"
        },
        {
            name: "CTRL",
            bit: 4,
            key: "Control_L"
        },
        {
            name: "ALT",
            bit: 8,
            key: "Alt_L"
        },
        {
            name: "SHIFT",
            bit: 1,
            key: "Shift_L"
        }
    ]

    function modifierKey(name: string): string {
        return root.modifiers.find(modifier => modifier.name === name)?.key ?? "";
    }

    // The keys of a row: a run of digits as a range, anything else side by
    // side, as the layout in use labels them.
    function keysLabel(keys): string {
        if (keys.length > 2 && keys.every((key, index) => /^[0-9]$/.test(key) && (index === 0 || Number(key) === Number(keys[index - 1]) + 1)))
            return keys[0] + "–" + keys[keys.length - 1];

        return keys.map(Keymap.label).join(" ");
    }

    function load(binds) {
        const merged = [];
        const byName = {};
        for (const bind of binds) {
            const description = bind.has_description ? bind.description : "";
            const key = bind.key !== "" ? bind.key : "code:" + bind.keycode;
            const name = description + "\n" + bind.modmask + "\n" + bind.submap;
            if (description !== "" && name in byName) {
                byName[name].keys.push(key);
                continue;
            }
            const row = {
                index: merged.length,
                description: description,
                modifiers: root.modifiers.filter(modifier => (bind.modmask & modifier.bit) !== 0).map(modifier => modifier.name),
                keys: [key]
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
}
