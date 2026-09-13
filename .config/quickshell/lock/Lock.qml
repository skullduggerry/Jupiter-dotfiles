// lock/Lock.qml
//
// The session lock surface itself: one WlSessionLock, whose `surface`
// component the compositor instantiates once per monitor. This file owns the
// window; LockService owns the state, so the bar's power menu can ask for a
// lock without bar/widgets importing lock/ (see PROJECT_STRUCTURE.md).
//
// This replaces the `hyprlock` process the power menu used to spawn. The
// compositor keeps the session locked until WlSessionLock.locked goes false,
// which only PAM success does — there is deliberately no IPC unlock.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../services"

Scope {
    id: lockScope

    // Manual/scripted trigger, compositor-independent:
    //   qs ipc call lock lock
    // `locked` is readable so a script can tell whether it worked; there is
    // no matching unlock, on purpose.
    IpcHandler {
        target: "lock"

        function lock(): void { LockService.lock() }
        function locked(): bool { return LockService.locked }
    }

    // Hyprland-native trigger, no process spawn per press. appid defaults to
    // "quickshell", so this registers as "quickshell:lock". Bind it with:
    //   hl.bind("SUPER + L", hl.dsp.global("quickshell:lock"))
    GlobalShortcut {
        name: "lock"
        onPressed: LockService.lock()
    }

    WlSessionLock {
        // LockService is the authority: PAM success clears it and the
        // compositor drops the lock, rather than the surface reaching into
        // this window to dismiss itself.
        locked: LockService.locked

        LockSurface {}
    }
}
