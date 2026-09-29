pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// The power button opens the power menu on the focused screen's bar. logind
// powers off on it unless someone holds a handle-power-key inhibitor, so the
// shell holds one while the session is unlocked: on the lock screen, at the
// greeter and with the shell gone, the button powers off as before.
Singleton {
    id: root

    // Set by the bar, which the shell always builds: a singleton is only built
    // on first use.
    property bool active: false

    // The output whose bar opens its power menu.
    signal menuRequested(string screen)

    GlobalShortcut {
        name: "powerMenu"
        onPressed: {
            if (Hyprland.focusedMonitor !== null)
                root.menuRequested(Hyprland.focusedMonitor.name);
        }
    }

    // With a parent-death signal, so a shell that dies hands the button back.
    Process {
        running: root.active && !LockService.locked
        command: ["setpriv", "--pdeathsig", "TERM", "systemd-inhibit", "--what=handle-power-key", "--mode=block", "--who=Quickshell", "--why=The power button opens the power menu", "sleep", "infinity"]
        onExited: (exitCode, exitStatus) => {
            if (root.active && !LockService.locked)
                console.warn("power button: systemd-inhibit exited with status", exitCode);
        }
    }
}
