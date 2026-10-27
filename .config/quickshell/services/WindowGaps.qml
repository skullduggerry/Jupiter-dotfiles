pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Where Hyprland puts windows: general:gaps_out from each edge of a screen
// (below the bar, from the strip it keeps), which .config/hypr/styles/
// layout.lua sets. A window's border is drawn inside that gap, so its outer
// edge is there whatever border_size is. The bar and what opens under it line
// up on it. Hyprland has no event for one option, so it is read with hyprctl
// at start and at every config reload; until its first answer, 0.
Singleton {
    id: root

    property int top: 0
    property int right: 0
    property int bottom: 0
    property int left: 0

    function read() {
        if (reader.running)
            reader.stale = true;
        else
            reader.running = true;
    }

    // Hyprland prints the gaps as CSS does: top, right, bottom, left, the
    // later ones left out where they repeat the earlier.
    function load(css: string) {
        const sides = css.trim().split(/\s+/).map(Number);
        if (sides.length === 0 || sides.length > 4 || sides.some(side => !Number.isFinite(side))) {
            console.warn("window gaps: hyprctl printed", JSON.stringify(css));
            return;
        }
        root.top = sides[0];
        root.right = sides[1] ?? sides[0];
        root.bottom = sides[2] ?? sides[0];
        root.left = sides[3] ?? sides[1] ?? sides[0];
    }

    Component.onCompleted: root.read()

    Connections {
        function onRawEvent(event: HyprlandEvent) {
            if (event.name === "configreloaded")
                root.read();
        }

        target: Hyprland
    }

    Process {
        id: reader

        // A reload during a read: read once more afterwards.
        property bool stale: false

        command: ["hyprctl", "-j", "getoption", "general:gaps_out"]
        onRunningChanged: {
            if (!reader.running && reader.stale) {
                reader.stale = false;
                reader.running = true;
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.load(JSON.parse(text).css);
                } catch (error) {
                    console.warn("window gaps: hyprctl printed no gaps:", error);
                }
            }
        }
    }
}
