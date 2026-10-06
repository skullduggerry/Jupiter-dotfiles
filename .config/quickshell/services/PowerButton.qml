pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// The power button opens the power menu on the full bar (BarLayout.main).
// logind powers off on it unless someone holds a handle-power-key inhibitor,
// so the shell holds one while the session is unlocked: on the lock screen, at
// the greeter and with the shell gone, the button powers off as before.
Singleton {
    id: root

    // Set by the bar, which the shell always builds: a singleton is only built
    // on first use.
    property bool active: false

    signal menuRequested

    GlobalShortcut {
        name: "powerMenu"
        onPressed: root.menuRequested()
    }

    // With a parent-death signal, so a shell that dies hands the button back.
    // Ended unasked (its `sleep` killed, say), it is taken again after `retake`.
    Process {
        running: root.active && !LockService.locked && !retake.running
        command: ["setpriv", "--pdeathsig", "TERM", "systemd-inhibit", "--what=handle-power-key", "--mode=block", "--who=Quickshell", "--why=The power button opens the power menu", "sleep", "infinity"]
        onExited: (exitCode, exitStatus) => {
            if (!root.active || LockService.locked)
                return;

            console.warn("power button: systemd-inhibit exited with status", exitCode, "- taking it again");
            retake.start();
        }
    }

    // A pause first, so an inhibitor logind refuses is not asked for in a loop.
    Timer {
        id: retake

        interval: 5000
    }
}
