pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Which screen has the full bar; every other screen has the small one, which
// either keeps a strip of its own or floats over windows. The Settings app's
// Displays page sets both, kept on this machine. The screen is kept by its
// port: it is known the moment a bar is built, where Hyprland's description
// arrives a moment later and would have the bars swap at every login. Until a
// screen is picked, or while it is unplugged, the full bar is on the one at the
// layout's top left.
Singleton {
    id: root

    readonly property ShellScreen topLeft: Quickshell.screens.reduce((best, screen) => best === null || screen.y < best.y || (screen.y === best.y && screen.x < best.x) ? screen : best, null)
    readonly property ShellScreen main: Quickshell.screens.find(screen => screen.name === settings.main) ?? root.topLeft
    readonly property bool floating: settings.floating

    // Whether a screen's bar floats over its windows, so what opens under the
    // bar there has to clear it by itself.
    function floats(screen: ShellScreen): bool {
        return root.floating && screen !== null && screen !== root.main;
    }

    function setMain(name: string) {
        settings.main = name;
        writeDebounce.restart();
    }

    function setFloating(floating: bool) {
        settings.floating = floating;
        writeDebounce.restart();
    }

    Component.onCompleted: settingsFile.text()

    Timer {
        id: writeDebounce

        interval: 200
        onTriggered: settingsFile.writeAdapter()
    }

    FileView {
        id: settingsFile

        path: Quickshell.statePath("bar.json")
        preload: true
        blockLoading: true
        printErrors: false
        watchChanges: false
        // An async write, once done, puts what it wrote back into the
        // adapter, undoing a change made meanwhile.
        blockWrites: true

        adapter: JsonAdapter {
            id: settings

            property string main: ""
            property bool floating: false
        }
    }
}
