import "../services"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

Scope {
    // No unlock over IPC, by design.
    IpcHandler {
        function lock(): void {
            LockService.lock();
        }

        function locked(): bool {
            return LockService.locked;
        }

        target: "lock"
    }

    GlobalShortcut {
        name: "lock"
        onPressed: LockService.lock()
    }

    WlSessionLock {
        locked: LockService.locked

        LockSurface {}
    }
}
