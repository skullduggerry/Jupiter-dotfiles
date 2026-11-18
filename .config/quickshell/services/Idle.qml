pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// How long the session may idle before hypridle locks it (the screens go off
// half a minute later) and before it suspends, in minutes, 0 for never: the
// Settings app's Power page picks them. hypridle gets them in a config of its
// own that sources .config/hypr/hypridle.conf, which keeps the times used
// without one, and is started again on it after a pick, as it reads its
// config only at start.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    // modules/startup.lua starts hypridle on this one once it exists.
    readonly property string config: StateFiles.path("hypridle.conf")
    readonly property string defaultConfig: (Quickshell.env("XDG_CONFIG_HOME") || root.home + "/.config") + "/hypr/hypridle.conf"
    readonly property int lockMinutes: root.minutes("lockAfter")
    readonly property int suspendMinutes: root.minutes("suspendAfter")
    // Seven each, which the Power page's lists show without scrolling.
    readonly property var lockChoices: root.labelled([1, 2, 5, 10, 15, 30, 0])
    readonly property var suspendChoices: root.labelled([5, 10, 15, 30, 60, 120, 0])

    // A `$name = seconds` line of the shell's config, else of the default
    // one, in minutes; empty is never.
    function minutes(name: string): int {
        const line = new RegExp("^\\$" + name + "[ \\t]*=[ \\t]*(\\d*)[ \\t]*$", "m");
        const match = kept.text().match(line) || defaults.text().match(line);
        return match === null ? 0 : Math.round(Number(match[1]) / 60);
    }

    function labelled(choices: list<int>): var {
        return choices.map(minutes => ({
                    label: minutes === 0 ? "Never" : minutes % 60 === 0 ? minutes / 60 + " h" : minutes + " min",
                    value: minutes
                }));
    }

    function setLockMinutes(minutes: int) {
        root.write(minutes, root.suspendMinutes);
    }

    function setSuspendMinutes(minutes: int) {
        root.write(root.lockMinutes, minutes);
    }

    function write(lock: int, suspend: int) {
        kept.setText(`# Written by the shell (.config/quickshell/services/Idle.qml).\n$idleFromShell = yes\n$lockAfter = ${lock > 0 ? lock * 60 : ""}\n$suspendAfter = ${suspend > 0 ? suspend * 60 : ""}\nsource = ${root.defaultConfig}\n`);
    }

    FileView {
        id: kept

        path: root.config
        blockLoading: true
        printErrors: false
        // Once it is on disk, so the new hypridle reads the new times.
        onSaved: Quickshell.execDetached([Quickshell.shellDir + "/services/hypridle-restart.sh", root.config])
    }

    FileView {
        id: defaults

        path: root.defaultConfig
        blockLoading: true
        printErrors: false
    }
}
