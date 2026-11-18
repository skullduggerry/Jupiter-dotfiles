pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// The drawing tablet. Where it draws and how its pen feels are Hyprland's
// (.config/hypr/modules/tablet.lua), kept in tablet.lua for its start and
// handed over live through hyprctl eval. What the pad's buttons (ExpressKeys)
// do is the shell's, because Hyprland gives them to the app under the pen and
// binds none: while one is bound, tablet.py reads the pad, and a press
// presses the bound shortcut as the keyboard would (modules/tablet.lua's
// press()) or holds the tablet.
Singleton {
    id: root

    // Reads the pad while a button is bound, from login (SettingsApp.qml).
    property bool active: false
    // tablet.py's last look: {name, width, height} and {buttons, readable},
    // each null when there is none.
    property var tablet: null
    property var pad: null

    // "all", "focused", or a screen's name.
    readonly property string area: settings.area
    readonly property bool keepRatio: settings.keepRatio
    readonly property bool leftHanded: settings.leftHanded
    // libinput's pressure range: how hard a stroke starts, and how hard it is
    // at full strength, from 0 to 1.
    readonly property real pressureMin: settings.pressureMin
    readonly property real pressureMax: settings.pressureMax
    // The Settings app's bounds for them, which keep the first below the
    // second, as libinput requires.
    readonly property real startsAtMost: 0.4
    readonly property real fullAtLeast: 0.5
    // The pad's buttons last seen, so they can be bound while it is away.
    readonly property int padButtons: root.pad !== null ? root.pad.buttons : settings.padButtons
    // A button's action: "" for none, "keys:" and a shortcut as Hyprland binds
    // spell it ("CTRL + SHIFT + z"), or one of the others in `actions`.
    readonly property list<string> buttons: settings.buttons
    readonly property var actions: [
        {
            label: "Nothing",
            value: ""
        },
        {
            label: "Undo",
            value: "keys:CTRL + z"
        },
        {
            label: "Redo",
            value: "keys:CTRL + SHIFT + z"
        },
        {
            label: "Save",
            value: "keys:CTRL + s"
        },
        {
            label: "Copy",
            value: "keys:CTRL + c"
        },
        {
            label: "Paste",
            value: "keys:CTRL + v"
        },
        {
            label: "Escape",
            value: "keys:Escape"
        },
        {
            label: "Hold to this screen",
            value: "screen"
        },
        {
            label: "Hold to this window",
            value: "window"
        },
        {
            label: "Quick menu",
            value: "quickmenu"
        }
    ]
    readonly property string helper: Quickshell.shellDir + "/services/tablet.py"

    function refresh() {
        describe.running = true;
    }

    function setArea(area: string) {
        settings.area = area;
        root.changed();
    }

    function setKeepRatio(keep: bool) {
        settings.keepRatio = keep;
        root.changed();
    }

    function setLeftHanded(left: bool) {
        settings.leftHanded = left;
        root.changed();
    }

    function setPressure(least: real, most: real) {
        settings.pressureMin = least;
        settings.pressureMax = most;
        root.changed();
    }

    function setButton(index: int, action: string) {
        const buttons = Array.from(root.buttons);
        while (buttons.length <= index)
            buttons.push("");
        buttons[index] = action;
        settings.buttons = buttons;
        writeDebounce.restart();
    }

    // "CTRL + SHIFT + z" as {mods, key}, or null if it is not a shortcut: a
    // keysym's name (or code:N), after any of Hyprland's modifiers. Nothing
    // else reaches the Lua it is sent as.
    function shortcut(text: string): var {
        const parts = text.split("+").map(part => part.trim());
        const key = parts.pop();
        const modifiers = ["SHIFT", "CTRL", "CONTROL", "ALT", "SUPER", "WIN", "LOGO", "MOD4", "META"];
        if (!/^([A-Za-z0-9_]+|code:[0-9]+)$/.test(key ?? "") || !parts.every(part => modifiers.includes(part.toUpperCase())))
            return null;
        return {
            mods: parts.map(part => part.toUpperCase()).join(" "),
            key: key
        };
    }

    // While the Settings app records a shortcut, every key goes to its window,
    // the desktop's binds too: modules/tablet.lua's submap, which Escape leaves.
    function setRecording(recording: bool) {
        Hyprland.dispatch(`hl.dsp.submap("${recording ? "tablet-record" : "reset"}")`);
    }

    function changed() {
        writeDebounce.restart();
        hyprlandDebounce.restart();
    }

    // What tablet.lua returns, and what modules/tablet.lua's use() takes.
    function luaSettings(): string {
        return `{ area = ${JSON.stringify(settings.area)}, keepRatio = ${settings.keepRatio}, leftHanded = ${settings.leftHanded}, pressureMin = ${settings.pressureMin.toFixed(2)}, pressureMax = ${settings.pressureMax.toFixed(2)}, width = ${settings.width}, height = ${settings.height} }`;
    }

    function evalLua(lua: string) {
        Quickshell.execDetached(["hyprctl", "eval", lua]);
    }

    function actionOf(index: int): string {
        return root.buttons[index] ?? "";
    }

    function press(index: int, down: bool) {
        // The pad's shortcuts go around Hyprland, which runs no bind but the
        // media keys' while the session is locked: none is pressed then.
        if (LockService.locked)
            return;

        const action = root.actionOf(index);
        if (action === "quickmenu") {
            root.evalLua(`require("modules.quickmenu").${down ? "press" : "release"}()`);
            return;
        }
        if (!down)
            return;

        if (action === "screen" || action === "window") {
            root.evalLua(`require("modules.tablet").${action === "screen" ? "holdScreen" : "holdWindow"}()`);
            return;
        }
        const keys = action.startsWith("keys:") ? root.shortcut(action.slice(5)) : null;
        if (keys !== null)
            root.evalLua(`require("modules.tablet").press(${JSON.stringify(keys.mods)}, ${JSON.stringify(keys.key)})`);
    }

    onActiveChanged: {
        if (root.active)
            root.refresh();
    }

    Process {
        id: describe

        command: ["python3", root.helper]

        stdout: StdioCollector {
            id: description

            onStreamFinished: {
                let found;
                try {
                    found = JSON.parse(description.text);
                } catch (error) {
                    console.warn("tablet: tablet.py printed no description:", error);
                    return;
                }
                root.tablet = found.tablet;
                root.pad = found.pad;
                // Hyprland needs the size for keepRatio, from its start.
                if (found.tablet !== null && (found.tablet.width !== settings.width || found.tablet.height !== settings.height)) {
                    settings.width = found.tablet.width;
                    settings.height = found.tablet.height;
                    root.changed();
                }
                if (found.pad !== null && found.pad.buttons !== settings.padButtons) {
                    settings.padButtons = found.pad.buttons;
                    writeDebounce.restart();
                }
            }
        }
    }

    Process {
        id: padReader

        // A custom shortcut not yet recorded ("keys:") does nothing.
        running: root.active && root.buttons.some(action => action !== "" && action !== "keys:")
        command: ["setpriv", "--pdeathsig", "TERM", "python3", root.helper, "pad"]

        stdout: SplitParser {
            onRead: line => {
                const [word, number] = line.split(" ");
                if (word === "press" || word === "release") {
                    root.press(parseInt(number), word === "press");
                } else if (word === "connected") {
                    // A tablet that was away when the shell started.
                    root.refresh();
                } else if (word === "shared") {
                    console.warn("tablet: could not grab the pad, so apps get its buttons too");
                }
            }
        }

        stderr: SplitParser {
            onRead: line => console.warn("tablet:", line)
        }
    }

    Timer {
        id: writeDebounce

        interval: 200
        onTriggered: {
            settingsFile.writeAdapter();
            kept.setText(`-- Written by the shell (.config/quickshell/services/Tablet.qml).\nreturn ${root.luaSettings()}\n`);
        }
    }

    // At most one hyprctl call per interval while a slider is dragged.
    Timer {
        id: hyprlandDebounce

        interval: 150
        onTriggered: root.evalLua(`require("modules.tablet").use(${root.luaSettings()})`)
    }

    FileView {
        id: settingsFile

        path: Quickshell.statePath("tablet.json")
        preload: true
        blockLoading: true
        printErrors: false
        watchChanges: false
        // An async write, once done, puts what it wrote back into the
        // adapter, undoing a change made meanwhile.
        blockWrites: true

        adapter: JsonAdapter {
            id: settings

            property string area: "all"
            property bool keepRatio: true
            property bool leftHanded: false
            property real pressureMin: 0
            property real pressureMax: 1
            property int width: 0
            property int height: 0
            property int padButtons: 0
            property list<string> buttons: []
        }
    }

    FileView {
        id: kept

        path: StateFiles.path("tablet.lua")
        preload: false
        printErrors: false
    }
}
