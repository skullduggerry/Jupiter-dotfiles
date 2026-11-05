pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Hyprland's decoration:blur as the Settings app picked it: sent live with
// `hyprctl eval`, and kept in blur.lua, which .config/hypr/styles/layout.lua
// applies at the next start. The Settings app hands everything in
// (SettingsApp.qml), the colours derived from the theme too, so the glass
// follows a new theme or accent as the shell does.
Singleton {
    id: root

    property bool active: false
    // Hyprland's variant number, its size, every sub-option by Hyprland's key
    // ("acrylic.clarity": 0.82), and the colours by key as "rgba(rrggbbaa)".
    property int variant: 0
    property int size: 6
    property var options: ({})
    property var colors: ({})
    readonly property string config: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/quickshell/blur.lua"

    // The blur as a Lua table: the sub-options grouped by variant
    // ({ acrylic = { clarity = 0.82 } }), the keys sorted so the file only
    // changes when a value does.
    function table(): string {
        const groups = {};
        const values = Object.assign({}, root.options, root.colors);
        for (const key of Object.keys(values).sort()) {
            // Indexed: Qt 6.11 reuses a destructured loop variable's values.
            const path = key.split(".");
            const value = values[key];
            if (groups[path[0]] === undefined)
                groups[path[0]] = [];
            groups[path[0]].push(`${path[1]} = ${typeof value === "string" ? JSON.stringify(value) : Number(value)}`);
        }
        const parts = [`variant = ${root.variant}`, `size = ${root.size}`];
        for (const group of Object.keys(groups).sort())
            parts.push(`${group} = { ${groups[group].join(", ")} }`);
        return `{ ${parts.join(", ")} }`;
    }

    onActiveChanged: send.restart()
    onVariantChanged: send.restart()
    onSizeChanged: send.restart()
    onOptionsChanged: send.restart()
    onColorsChanged: send.restart()

    // At most one hyprctl call per moment while a slider is dragged.
    Timer {
        id: send

        interval: 150
        onTriggered: {
            if (!root.active)
                return;

            const blur = root.table();
            kept.setText(`-- Written by the shell (.config/quickshell/services/HyprBlur.qml).\nreturn ${blur}\n`);
            Quickshell.execDetached(["hyprctl", "eval", `hl.config({ decoration = { blur = ${blur} } })`]);
        }
    }

    FileView {
        id: kept

        path: root.config
        preload: false
        printErrors: false
    }
}
