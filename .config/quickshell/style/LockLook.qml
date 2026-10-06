pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// How the lock and login screens look: each its own background, and one style
// for both. Set on the Settings app's Appearance page, Lock Screen tab. The greeter gets a
// copy of style/ and can read nothing of $HOME, so scripts/install-greeter.sh
// installs this file beside it and the greeter's compositor names it in
// LOCKSCREEN_STYLE; there it is only ever read.
Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"
    readonly property string file: Quickshell.env("LOCKSCREEN_STYLE") || root.stateDir + "/quickshell/lockscreen.json"
    // "wallpaper" (the desktop's), "image" (the one below) or "plain".
    readonly property string lockBackground: settings.lockBackground
    readonly property string lockImage: settings.lockImage
    readonly property string loginBackground: settings.loginBackground
    readonly property string loginImage: settings.loginImage
    // "typing" blurs the background once a key is pressed, "always" from the
    // start, "off" never.
    readonly property string blur: settings.blur
    // How dark the scrim over the background is.
    readonly property real dim: settings.dim
    readonly property bool clock: settings.clock

    function blurFor(engaged: bool): real {
        return root.blur === "always" || (root.blur === "typing" && engaged) ? Style.lock.blurAmount : 0;
    }

    function set(name: string, value: var) {
        settings[name] = value;
        writeDebounce.restart();
    }

    Component.onCompleted: settingsFile.text()

    Timer {
        id: writeDebounce

        interval: 200
        onTriggered: settingsFile.writeAdapter()
    }

    // Not Quickshell.statePath(), for the greeter's sake, as in Theme.
    FileView {
        id: settingsFile

        path: root.file
        preload: true
        blockLoading: true
        printErrors: false
        watchChanges: false

        adapter: JsonAdapter {
            id: settings

            property string lockBackground: "wallpaper"
            property string lockImage: ""
            property string loginBackground: "wallpaper"
            property string loginImage: ""
            property string blur: "typing"
            property real dim: 0.45
            property bool clock: true
        }
    }
}
