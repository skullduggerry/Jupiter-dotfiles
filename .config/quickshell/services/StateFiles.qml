pragma Singleton

import QtQuick
import Quickshell

// $XDG_STATE_HOME/quickshell: what the shell keeps for others that read it
// at this fixed path (Hyprland's modules, install-greeter.sh, apply.sh), as
// Quickshell.statePath()'s folder, named by the shell's own path, is not.
// style/ (Theme, LockLook) spells it out, for the greeter.
Singleton {
    id: root

    readonly property string folder: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/quickshell"

    function path(name: string): string {
        return root.folder + "/" + name;
    }
}
