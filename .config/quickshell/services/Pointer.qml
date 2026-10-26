pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The mouse's and the touchpad's speed and scrolling. They are Hyprland's
// (.config/hypr/modules/pointer.lua), kept in pointer.lua for its start and
// handed over live through hyprctl eval. Hyprland has no sensitivity for
// every touchpad, so the touchpads are named: the pointers hyprctl lists
// whose name says they are one, as libinput's names do.
Singleton {
    id: root

    // libinput's speed, from -1 to 1, 0 being the device's own.
    readonly property real mouseSpeed: settings.mouseSpeed
    readonly property real touchpadSpeed: settings.touchpadSpeed
    // How far a notch of the wheel or a swipe scrolls, 1 as the app asks.
    readonly property real mouseScroll: settings.mouseScroll
    readonly property real touchpadScroll: settings.touchpadScroll
    // The Settings app's bounds for scrolling, as many times less as more.
    readonly property real scrollLeast: 0.25
    readonly property real scrollMost: 4
    // Every touchpad seen, so one keeps its speed while away.
    readonly property list<string> touchpads: settings.touchpads

    function refresh() {
        reader.running = true;
    }

    function setMouse(speed: real, scroll: real) {
        settings.mouseSpeed = root.speed(speed);
        settings.mouseScroll = root.scroll(scroll);
        root.changed();
    }

    function setTouchpad(speed: real, scroll: real) {
        settings.touchpadSpeed = root.speed(speed);
        settings.touchpadScroll = root.scroll(scroll);
        root.changed();
    }

    function speed(value: real): real {
        return Math.max(-1, Math.min(1, value));
    }

    function scroll(value: real): real {
        return Math.max(root.scrollLeast, Math.min(root.scrollMost, value));
    }

    // A name goes into the Lua Hyprland runs, so only one spelt as Hyprland
    // spells devices is taken: lower case, dashes for spaces.
    function isTouchpad(name: string): bool {
        return /^[a-z0-9:._-]+$/.test(name) && /touchpad|trackpad/.test(name);
    }

    function changed() {
        writeDebounce.restart();
        hyprlandDebounce.restart();
    }

    // What pointer.lua returns, and what modules/pointer.lua's use() takes.
    function luaSettings(): string {
        const touchpads = settings.touchpads.map(name => JSON.stringify(name)).join(", ");
        return `{ mouseSpeed = ${settings.mouseSpeed.toFixed(2)}, mouseScroll = ${settings.mouseScroll.toFixed(2)}, touchpadSpeed = ${settings.touchpadSpeed.toFixed(2)}, touchpadScroll = ${settings.touchpadScroll.toFixed(2)}, touchpads = { ${touchpads} } }`;
    }

    // Added to the ones kept, never in their place: a touchpad unplugged
    // while the page opens is still given its speed when it is back.
    function load(mice) {
        const found = mice.map(mouse => mouse.name).filter(name => root.isTouchpad(name) && !settings.touchpads.includes(name));
        if (found.length === 0)
            return;
        settings.touchpads = Array.from(settings.touchpads).concat(found);
        root.changed();
    }

    Process {
        id: reader

        command: ["hyprctl", "devices", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.load(JSON.parse(text).mice);
                } catch (error) {
                    console.warn("pointer: hyprctl printed no devices:", error);
                }
            }
        }
    }

    Timer {
        id: writeDebounce

        interval: 200
        onTriggered: {
            settingsFile.writeAdapter();
            kept.setText(`-- Written by the shell (.config/quickshell/services/Pointer.qml).\nreturn ${root.luaSettings()}\n`);
        }
    }

    // At most one hyprctl call per interval while a slider is dragged: each
    // one sets Hyprland's input devices up again.
    Timer {
        id: hyprlandDebounce

        interval: 150
        onTriggered: Quickshell.execDetached(["hyprctl", "eval", `require("modules.pointer").use(${root.luaSettings()})`])
    }

    FileView {
        id: settingsFile

        path: Quickshell.statePath("pointer.json")
        preload: true
        blockLoading: true
        printErrors: false
        watchChanges: false

        adapter: JsonAdapter {
            id: settings

            property real mouseSpeed: 0
            property real mouseScroll: 1
            property real touchpadSpeed: 0
            property real touchpadScroll: 1
            property list<string> touchpads: []
        }
    }

    FileView {
        id: kept

        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/quickshell/pointer.lua"
        preload: false
        printErrors: false
    }
}
