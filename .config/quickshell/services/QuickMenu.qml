pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The quick menu's layout and behaviour (quickmenu/), which the pencil at its
// centre changes, and whether Caps Lock opens it, which the Settings app's
// Keyboard page does. That last one is Hyprland's as well: kept in
// quickmenu.lua, which .config/hypr/modules/keybinds.lua applies at every
// start, and switched live through modules/quickmenu.lua.
Singleton {
    id: root

    readonly property list<int> counts: [4, 6, 8]
    // A slot holds "category:ID", "item:ID" or "" for nothing, clockwise from
    // the top; quickmenu/QuickMenuItems says what the IDs are.
    readonly property var defaultSlots: ({
            "4": ["category:network", "category:sound", "category:media", "item:apps"],
            "6": ["category:network", "category:bluetooth", "category:sound", "category:media", "category:capture", "item:apps"],
            "8": ["category:network", "category:bluetooth", "category:sound", "category:display", "category:media", "category:capture", "item:apps", "item:clipboard"]
        })
    readonly property list<string> slots: settings.slots.length > 0 ? settings.slots : root.defaultSlots["8"]
    // Category ID -> the item IDs it shows, for those changed here.
    readonly property var categories: settings.categories
    readonly property bool closeAfterClick: settings.closeAfterClick
    readonly property bool playful: settings.playful
    // "halo" (one disc), "orbit" (round buttons) or "auto", which the menu
    // reads as Orbit over blur and Halo over a solid surface.
    readonly property list<string> looks: ["auto", "halo", "orbit"]
    readonly property string look: root.looks.includes(settings.look) ? settings.look : "auto"
    // How large it is drawn, one of Style.quickMenu.sizes.
    readonly property real size: settings.size
    readonly property bool capsLock: settings.capsLock

    function setSlot(index: int, value: string) {
        const slots = Array.from(root.slots);
        slots[index] = value;
        settings.slots = slots;
        writeDebounce.restart();
    }

    function swap(from: int, to: int) {
        const slots = Array.from(root.slots);
        slots[from] = root.slots[to];
        slots[to] = root.slots[from];
        settings.slots = slots;
        writeDebounce.restart();
    }

    // Fewer or more slots keep what the first ones hold, then the defaults.
    function setCount(count: int) {
        const kept = root.slots.filter(slot => slot !== "").slice(0, count);
        settings.slots = kept.concat(root.defaultSlots[count].filter(slot => !kept.includes(slot))).slice(0, count);
        writeDebounce.restart();
    }

    function setItems(category: string, items: list<string>) {
        const categories = Object.assign({}, settings.categories);
        categories[category] = Array.from(items);
        settings.categories = categories;
        writeDebounce.restart();
    }

    function reset() {
        settings.slots = [];
        settings.categories = {};
        writeDebounce.restart();
    }

    function setCloseAfterClick(close: bool) {
        settings.closeAfterClick = close;
        writeDebounce.restart();
    }

    function setSize(size: real) {
        settings.size = size;
        writeDebounce.restart();
    }

    function setPlayful(playful: bool) {
        settings.playful = playful;
        writeDebounce.restart();
    }

    function setLook(look: string) {
        settings.look = look;
        writeDebounce.restart();
    }

    function setCapsLock(enabled: bool) {
        settings.capsLock = enabled;
        writeDebounce.restart();
        kept.setText(`-- Written by the shell (.config/quickshell/services/QuickMenu.qml).\nreturn { capsLock = ${enabled} }\n`);
        Quickshell.execDetached(["hyprctl", "eval", `require("modules.quickmenu").useCapsLock(${enabled})`]);
    }

    Timer {
        id: writeDebounce

        interval: 200
        onTriggered: settingsFile.writeAdapter()
    }

    FileView {
        id: settingsFile

        path: Quickshell.statePath("quick-menu.json")
        preload: true
        blockLoading: true
        printErrors: false
        watchChanges: false

        adapter: JsonAdapter {
            id: settings

            property list<string> slots: []
            property var categories: ({})
            property bool closeAfterClick: false
            property bool playful: true
            property string look: "auto"
            property real size: 1.2
            property bool capsLock: true
        }
    }

    FileView {
        id: kept

        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/quickshell/quickmenu.lua"
        preload: false
        printErrors: false
    }
}
