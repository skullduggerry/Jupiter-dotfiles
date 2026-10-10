pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

Singleton {
    id: root

    property alias locked: lockState.locked
    property string password: ""
    property string errorText: ""
    // What PAM asks after the password (a code, a new password), "" while the
    // field is for the password itself.
    property string prompt: ""
    property bool promptVisible: false
    readonly property bool answering: pam.active && pam.responseRequired && root.answered
    readonly property bool authenticating: pam.active && !root.answering
    readonly property string pamConfig: "login"
    // Whether this attempt's password went out, so a later question waits
    // for an answer of its own.
    property bool answered: false
    // What PAM said during this attempt (pam_faillock's lockout, say), which
    // a failure shows rather than a guess.
    property list<string> said: []

    function lock() {
        if (root.locked)
            return;

        root.password = "";
        root.errorText = "";
        root.locked = true;
    }

    function submit() {
        if (root.password === "")
            return;

        if (root.answering) {
            const answer = root.password;
            root.password = "";
            root.prompt = "";
            pam.respond(answer);
            return;
        }
        if (pam.active)
            return;

        root.errorText = "";
        root.said = [];
        root.answered = false;
        pam.start();
    }

    onPasswordChanged: {
        if (root.password !== "")
            root.errorText = "";
    }
    onLockedChanged: lockFile.setText(root.locked ? "locked\n" : "")
    // A shell that crashed while locked comes back unlocked (Quickshell's
    // crash handler starts it again), and Hyprland keeps the screen covered
    // until a lock takes over (misc.allow_session_lock_restore): lock again.
    Component.onCompleted: {
        if (!root.locked && lockFile.text().trim() === "locked")
            root.locked = true;
    }

    PersistentProperties {
        id: lockState

        property bool locked: false

        reloadableId: "lockState"
    }

    // Per Hyprland instance, so a new session never starts out locked.
    FileView {
        id: lockFile

        path: Quickshell.env("XDG_RUNTIME_DIR") + "/hypr/" + Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") + "/quickshell-locked"
        blockLoading: true
        printErrors: false
    }

    PamContext {
        id: pam

        config: root.pamConfig
        onPamMessage: {
            if (!pam.responseRequired) {
                if (pam.message !== "") {
                    root.said = root.said.concat([pam.message]);
                    root.errorText = root.said.join("\n");
                }
                return;
            }
            // The password typed before Enter answers the first question;
            // anything asked after it is shown and answered from the field.
            if (!root.answered) {
                root.answered = true;
                pam.respond(root.password);
                return;
            }
            root.password = "";
            root.prompt = pam.message;
            root.promptVisible = pam.responseVisible;
        }
        onCompleted: result => {
            root.password = "";
            root.prompt = "";
            root.promptVisible = false;
            root.answered = false;
            if (result === PamResult.Success) {
                root.errorText = "";
                root.locked = false;
                return;
            }
            root.errorText = result === PamResult.MaxTries ? "Too many attempts" : root.said.length > 0 ? root.said.join("\n") : "Incorrect password";
        }
        onError: error => {
            root.password = "";
            root.prompt = "";
            root.promptVisible = false;
            root.answered = false;
            root.errorText = "PAM: " + PamError.toString(error);
        }
    }
}
