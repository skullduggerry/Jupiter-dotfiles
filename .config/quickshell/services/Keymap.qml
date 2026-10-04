pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// The keys of Hyprland's keyboard layouts as xkbcommon compiles them
// (keymap.py): what each key says in the layout in use, and which key a bind
// is on. Hyprland looks a bind's key up in the first layout whichever is in
// use, unless input:resolve_binds_by_sym is set, so a bind can be on a key
// that says something else: SUPER + Z is SUPER and the key labelled Y on de.
Singleton {
    id: root

    // Per layout: whether it is drawn ISO, and its keys by XKB name, each
    // with its keycode and the keysyms and text of its first two levels.
    property var layouts: []
    property bool resolveBySym: false
    readonly property var keys: root.layouts[KeyboardLayout.index]?.keys ?? {}
    readonly property bool iso: root.layouts[KeyboardLayout.index]?.iso ?? false
    // The key a keysym (by lower-case name) or a keycode ("code:24") is on,
    // in the layout binds go by; the lower keycode where two keys have it.
    readonly property var placed: {
        const placed = {};
        const keys = root.layouts[root.resolveBySym ? KeyboardLayout.index : 0]?.keys ?? {};
        for (const name in keys) {
            const sym = keys[name].syms[0].toLowerCase();
            if (!(sym in placed))
                placed[sym] = name;
            placed["code:" + keys[name].code] = name;
        }
        return placed;
    }
    // A string, so that only a real change of layouts reads them again.
    readonly property string layoutNames: KeyboardLayout.codes.join(",") + " " + KeyboardLayout.variants.join(",")

    // The XKB name of the key a bind's key is on, as written in the bind (a
    // keysym's name, "slash", or code:N), "" for one no key has.
    function keyOf(key: string): string {
        return root.placed[key.toLowerCase()] ?? "";
    }

    // What a key's cap says in the layout in use, top to bottom: a letter in
    // capitals, a character under Shift's ([shifted, base]), or its name.
    function legend(name: string): list<string> {
        const key = root.keys[name];
        if (key === undefined)
            return [""];

        const [base, shifted] = key.text;
        if (base === "")
            return [root.keyName(key.syms[0])];

        if (shifted !== base && shifted === base.toUpperCase())
            return [shifted];

        return shifted === "" || shifted === base ? [base] : [shifted, base];
    }

    // A bind's key as the layout in use labels the key it is on.
    function label(key: string): string {
        const name = root.keyOf(key);
        if (name === "")
            return root.keyName(key);

        const legend = root.legend(name);
        return legend[legend.length - 1];
    }

    // A keysym's name as a keycap says it.
    function keyName(key: string): string {
        const names = {
            Left: "←",
            Right: "→",
            Up: "↑",
            Down: "↓",
            Print: "Print",
            Return: "Enter",
            space: "Space",
            Escape: "Esc",
            BackSpace: "Backspace",
            Caps_Lock: "Caps",
            Control_L: "Ctrl",
            Control_R: "Ctrl",
            Shift_L: "Shift",
            Shift_R: "Shift",
            Alt_L: "Alt",
            Alt_R: "Alt",
            Super_L: "Super",
            Super_R: "Super",
            ISO_Level3_Shift: "AltGr",
            Insert: "Ins",
            Delete: "Del",
            Prior: "PgUp",
            Next: "PgDn",
            Scroll_Lock: "ScrLk",
            XF86AudioRaiseVolume: "Volume Up",
            XF86AudioLowerVolume: "Volume Down",
            XF86AudioMute: "Mute",
            XF86AudioPlay: "Play",
            XF86AudioPause: "Pause",
            XF86AudioNext: "Next",
            XF86AudioPrev: "Previous",
            XF86MonBrightnessUp: "Brightness Up",
            XF86MonBrightnessDown: "Brightness Down"
        };
        // Binds name keys in any case: PRINT is Print.
        const known = Object.keys(names).find(name => name.toLowerCase() === key.toLowerCase());
        if (known !== undefined)
            return names[known];

        if (key.startsWith("XF86"))
            return key.slice(4).replace(/([a-z])([A-Z])/g, "$1 $2");

        return key.length === 1 ? key.toUpperCase() : key.charAt(0).toUpperCase() + key.slice(1);
    }

    function read() {
        if (KeyboardLayout.codes.length === 0)
            return;

        if (reader.running) {
            reader.stale = true;
            return;
        }
        reader.command = ["python3", Quickshell.shellDir + "/services/keymap.py", KeyboardLayout.codes.join(","), KeyboardLayout.variants.join(",")];
        reader.running = true;
    }

    Component.onCompleted: root.read()
    onLayoutNamesChanged: root.read()

    // The rules, model and options may have changed with the config.
    Connections {
        function onRawEvent(event: HyprlandEvent) {
            if (event.name === "configreloaded")
                root.read();
        }

        target: Hyprland
    }

    Process {
        id: reader

        // The layouts changed during a read: read once more afterwards.
        property bool stale: false

        onRunningChanged: {
            if (!reader.running && reader.stale) {
                reader.stale = false;
                root.read();
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const keymap = JSON.parse(text);
                    root.layouts = keymap.layouts;
                    root.resolveBySym = keymap.resolveBySym;
                } catch (error) {
                    console.warn("keymap: keymap.py printed no keys:", error);
                }
            }
        }

        // Why it printed none, or what it had to do without.
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    console.warn(text.trim());
            }
        }
    }
}
