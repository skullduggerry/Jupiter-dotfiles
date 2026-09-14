import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../services"

Scope {
    id: lockScope

    IpcHandler {
        target: "lock"

        function lock(): void { LockService.lock() }
        function locked(): bool { return LockService.locked }
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
