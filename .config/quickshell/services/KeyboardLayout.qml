pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// The keyboard layouts Hyprland has (input.kb_layout and kb_variant) and the
// one in use. Its event names a change only by the layout's long name, so the
// keyboard is read back with hyprctl; a switch sets every keyboard to the same
// layout. The Settings app's Keyboard page changes the list (setLayouts).
Singleton {
    id: root

    // As Hyprland has them, "us" and "de", and a variant for each ("" for none).
    property list<string> codes: []
    property list<string> variants: []
    // What the bar shows, "US"; a layout listed twice adds its variant.
    readonly property list<string> layouts: root.codes.map((code, position) => (root.codes.indexOf(code) !== root.codes.lastIndexOf(code) && root.variants[position] ? code + " " + root.variants[position] : code).toUpperCase())
    property int index: 0
    // XKB's name for the one in use, "English (US)".
    property string name: ""
    readonly property string label: root.layouts[root.index] ?? ""

    function select(index: int) {
        switcher.command = ["hyprctl", "switchxkblayout", "all", String(index)];
        switcher.running = true;
    }

    function next() {
        if (root.layouts.length > 1)
            root.select((root.index + 1) % root.layouts.length);
    }

    // Kept on this machine for config/hypr/modules/keybinds.lua, which applies
    // it at every start, and applied now, staying on the layout in use.
    function setLayouts(codes: list<string>, variants: list<string>) {
        const input = `{ kb_layout = ${JSON.stringify(codes.join(","))}, kb_variant = ${JSON.stringify(variants.join(","))} }`;
        kept.setText(`-- Written by the shell (config/quickshell/services/KeyboardLayout.qml).\nreturn ${input}\n`);
        applier.keep = Math.max(0, codes.findIndex((code, position) => code === root.codes[root.index] && variants[position] === root.variants[root.index]));
        applier.command = ["hyprctl", "eval", `hl.config({ input = ${input} })`];
        applier.running = true;
    }

    function read() {
        if (reader.running)
            reader.stale = true;
        else
            reader.running = true;
    }

    function load(keyboards) {
        // The keyboard typed on last, but never a virtual one (KDE Connect's
        // remote input, an input method), which starts out on the first
        // layout whatever the others are on.
        const physical = keyboards.filter(candidate => !candidate.name.startsWith("hl-virtual-keyboard"));
        const keyboard = physical.find(candidate => candidate.main) ?? physical[0];
        if (keyboard === undefined) {
            root.codes = [];
            return;
        }

        const variants = keyboard.variant.split(",");
        root.codes = keyboard.layout.split(",");
        root.variants = root.codes.map((code, position) => variants[position] ?? "");
        root.index = keyboard.active_layout_index;
        root.name = keyboard.active_keymap;
    }

    Component.onCompleted: root.read()

    GlobalShortcut {
        name: "keyboardLayout"
        onPressed: root.next()
    }

    Connections {
        function onRawEvent(event: HyprlandEvent) {
            if (event.name === "activelayout" || event.name === "configreloaded")
                root.read();
        }

        target: Hyprland
    }

    FileView {
        id: kept

        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/quickshell/keyboard.lua"
        preload: false
        printErrors: false
    }

    // A new keymap starts on the first layout, so the one in use before is
    // switched back to.
    Process {
        id: applier

        property int keep: 0

        onExited: root.select(applier.keep)
    }

    // Read back rather than wait for the event: Hyprland (0.56) sends none for
    // a switch to the layout it was on before the layouts last changed.
    Process {
        id: switcher

        onExited: root.read()
    }

    Process {
        id: reader

        // A change that came in during a read: read once more afterwards.
        property bool stale: false

        command: ["hyprctl", "devices", "-j"]
        onRunningChanged: {
            if (!reader.running && reader.stale) {
                reader.stale = false;
                reader.running = true;
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.load(JSON.parse(text).keyboards);
                } catch (error) {
                    console.warn("keyboard layout: hyprctl printed no devices:", error);
                }
            }
        }
    }
}
