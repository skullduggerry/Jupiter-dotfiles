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
    // A question after the password, in the field and waiting for its
    // answer. pam.responseRequired stays true after an answer until PAM
    // speaks again, so it cannot say this: while the password was checked
    // the lock looked idle, and a second Enter answered it again.
    property bool answering: false
    readonly property bool authenticating: pam.active && !root.answering
    readonly property string pamConfig: "login"
    // Whether this attempt's password went out, so a later question waits
    // for an answer of its own.
    property bool answered: false
    // What PAM said during this attempt (pam_faillock's lockout, say), which
    // a failure shows rather than a guess.
    property list<string> said: []
    // A finger unlocks too: pam/fingerprint.conf runs pam_fprintd on its own,
    // beside the password, because in the password's stack every attempt
    // would wait on the reader first. An attempt that never asked for a
    // finger found no reader or no enrolled print (fprintd-enroll) and is not
    // repeated until the next lock; one that timed out is; too many failed
    // matches leave the password.
    readonly property bool fingerprint: fingerprintPam.active && root.fingerprintAsked
    property bool fingerprintAsked: false

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
            root.answering = false;
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
    function listenForFinger() {
        root.fingerprintAsked = false;
        if (root.locked && !fingerprintPam.active)
            fingerprintPam.start();
        else if (!root.locked && fingerprintPam.active)
            fingerprintPam.abort();
    }

    onLockedChanged: {
        lockFile.setText(root.locked ? "locked\n" : "");
        root.listenForFinger();
    }
    // A shell that crashed while locked comes back unlocked (Quickshell's
    // crash handler starts it again), and Hyprland keeps the screen covered
    // until a lock takes over (misc.allow_session_lock_restore): lock again.
    // One reloaded while locked listens for a finger again.
    Component.onCompleted: {
        if (!root.locked && lockFile.text().trim() === "locked")
            root.locked = true;
        else
            root.listenForFinger();
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
            root.answering = true;
        }
        onCompleted: result => {
            root.password = "";
            root.prompt = "";
            root.promptVisible = false;
            root.answered = false;
            root.answering = false;
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
            root.answering = false;
            root.errorText = "PAM: " + PamError.toString(error);
        }
    }

    PamContext {
        id: fingerprintPam

        config: "fingerprint.conf"
        configDirectory: Quickshell.shellPath("pam")
        onPamMessage: {
            // pam_fprintd only tells (place a finger, no match); a question
            // would come from a stack that is not this one.
            if (fingerprintPam.responseRequired)
                fingerprintPam.abort();
            else
                root.fingerprintAsked = true;
        }
        onCompleted: result => {
            if (!root.locked)
                return;
            if (result === PamResult.Success) {
                if (pam.active)
                    pam.abort();
                root.password = "";
                root.errorText = "";
                root.locked = false;
            } else if (result === PamResult.MaxTries) {
                root.errorText = "Fingerprint not recognised: type the password";
            } else if (root.fingerprintAsked) {
                fingerprintRetry.restart();
            }
        }
    }

    // A moment between attempts, so a reader that fails at once (just after
    // a resume, say) is not asked again in a loop.
    Timer {
        id: fingerprintRetry

        interval: 1000
        onTriggered: root.listenForFinger()
    }
}
