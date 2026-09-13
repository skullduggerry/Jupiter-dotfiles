// services/LockService.qml
//
// Session lock state and the PAM conversation behind it.
//
// Shared state rather than state inside lock/Lock.qml for the same reason
// DropdownState is: more than one surface drives it. The bar's power menu
// asks for a lock, the compositor's keybind asks over a GlobalShortcut, and
// every monitor's lock surface reads the same password buffer and error back
// out. Putting it here keeps bar/widgets and lock/ both depending on
// services/ instead of on each other.
//
// The buffer is mirrored across surfaces on purpose: with two monitors, the
// lock covers both, and typing has to show up wherever the user started.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pam

Singleton {
    id: root

    // The authority on whether the session is locked. lock/Lock.qml binds
    // WlSessionLock.locked to this, so unlocking is a matter of clearing it
    // rather than reaching into the window.
    //
    // Held in PersistentProperties so it survives a config reload. Without
    // that, saving any QML file while the screen was locked reset this to
    // false and the compositor dropped the lock — which needed filesystem
    // access nobody at a locked screen has, but still meant the lock could
    // not survive the shell reloading under it.
    //
    // Reload state lives in memory, not on disk, so killing quickshell
    // outright still clears it. That is the intended escape hatch, and the
    // reason this can't strand a session on its own.
    property alias locked: lockState.locked

    // What has been typed so far, shared by every monitor's surface.
    property string password: ""

    // Why the last attempt didn't work, shown under the field. Cleared on
    // the next keystroke so a stale "Incorrect password" doesn't sit there
    // while the user retypes.
    property string errorText: ""

    // A conversation is in flight: the field is read-only and the ring
    // around it switches to the busy color rather than the surface pretending
    // nothing was submitted.
    readonly property bool authenticating: pam.active

    // The pam.d config to authenticate against. "login" is what hyprlock and
    // the other session lockers on Arch use (/etc/pam.d/hyprlock is a
    // one-line include of it), and pam_unix authenticates the calling user
    // through the setuid unix_chkpwd helper, so quickshell does not need to
    // be privileged.
    readonly property string pamConfig: "login"

    function lock() {
        if (root.locked) return
        root.password = ""
        root.errorText = ""
        root.locked = true
    }

    function submit() {
        if (pam.active || root.password === "") return
        root.errorText = ""
        pam.start()
    }

    onPasswordChanged: if (root.password !== "") root.errorText = ""

    PersistentProperties {
        id: lockState
        reloadableId: "lockState"

        property bool locked: false
    }

    PamContext {
        id: pam

        config: root.pamConfig

        // PAM drives the exchange: it asks (usually once, for the password)
        // and this answers with the buffer. A message that needs no response
        // is PAM talking — a faillock countdown, an expiry warning — and is
        // worth showing rather than dropping.
        onPamMessage: {
            if (pam.responseRequired) pam.respond(root.password)
            else if (pam.message !== "") root.errorText = pam.message
        }

        onCompleted: (result) => {
            root.password = ""
            if (result === PamResult.Success) {
                root.errorText = ""
                root.locked = false
                return
            }
            root.errorText = result === PamResult.MaxTries
                ? "Too many attempts"
                : "Incorrect password"
        }

        // Failing to even start the conversation is a configuration problem
        // (a missing pam.d entry, a broken stack), not a wrong password, and
        // saying "Incorrect password" for it would send the user hunting for
        // the wrong thing (llm.md §14).
        onError: (error) => {
            root.password = ""
            root.errorText = "PAM: " + PamError.toString(error)
        }
    }
}
