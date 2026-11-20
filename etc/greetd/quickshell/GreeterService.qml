pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Greetd

// Logging in through greetd (GREETD_SOCK), with Quickshell's own client.
// greeter-env.py lists who can log in and the sessions to start.
Singleton {
    id: root

    property var users: []
    property var sessions: []
    property bool listed: false
    // fprintd has a reader (greeter-env.py): the greeter asks for a finger
    // by itself once it has the users, and again for Enter on an empty
    // field, by answering the password's question with nothing, which
    // etc/pam.d/greetd sends to pam_fprintd. greetd answers nothing else
    // until the reader is done (a finger, or its timeout there), so a
    // password entered meanwhile waits for it (queued). Without a reader,
    // an empty field sends nothing, as ever.
    property bool fingerprint: false
    // This attempt is a finger's: its first question is answered empty.
    property bool fingerAttempt: false
    // The reader has greetd, from the empty answer until it is done.
    property bool scanning: false
    // A scan whose ending without a finger is no error to the user: the
    // greeter's own (its timeout), or one for a user no longer picked.
    property bool autoScan: false
    // Enter on a password while the reader had greetd: sent once it is done.
    property bool queued: false
    readonly property string noPassword: "No password entered!"
    property string username: ""
    property string sessionExec: ""
    property string password: ""
    property string errorText: ""
    // As the lock screen's, scanning or not.
    readonly property string passwordPrompt: root.fingerprint ? "Password or fingerprint" : "Password"
    property string promptText: root.passwordPrompt
    property bool promptSecret: true
    // A question asked after the password went out (a code, say), which the
    // field answers rather than starting a new login.
    property bool answering: false
    // What PAM said during this attempt (pam_faillock's lockout, say), which
    // a failed one shows rather than greetd's own error.
    property list<string> said: []
    readonly property bool ready: root.listed && Greetd.available
    property bool busy: false
    readonly property bool canSubmit: root.ready && !root.busy && root.username !== "" && root.sessionExec !== ""

    function submit() {
        if (root.scanning) {
            if (root.password !== "") {
                root.errorText = "";
                root.queued = true;
                root.busy = true;
            }
            return;
        }
        if (!root.canSubmit)
            return;
        const finger = root.password === "" && !root.answering && root.fingerprint;
        if (root.password === "" && !finger) {
            root.errorText = root.answering ? "" : root.noPassword;
            return;
        }

        root.errorText = "";
        if (finger) {
            root.scan(false);
            return;
        }
        root.busy = true;
        if (root.answering) {
            const answer = root.password;
            root.password = "";
            root.answering = false;
            Greetd.respond(answer);
            return;
        }
        root.login();
    }

    function login() {
        root.said = [];
        Greetd.createSession(root.username);
    }

    function scan(auto: bool) {
        root.said = [];
        root.fingerAttempt = true;
        root.scanning = true;
        root.autoScan = auto;
        Greetd.createSession(root.username);
    }

    // The reader is done without a finger it knows. A manual scan says what
    // it said; one the greeter began says nothing, as no finger came.
    function scanFailed(message: string) {
        const auto = root.autoScan;
        root.scanning = false;
        root.autoScan = false;
        root.fingerAttempt = false;
        if (root.queued) {
            root.sendQueued();
            return;
        }
        root.promptText = root.passwordPrompt;
        root.promptSecret = true;
        root.errorText = auto ? "" : message;
    }

    // Once greetd has ended the reader's login, the password entered
    // meanwhile starts one of its own.
    function sendQueued() {
        if (!root.queued || root.scanning || Greetd.state !== GreetdState.Inactive)
            return;
        root.queued = false;
        root.login();
    }

    function preferredSession(available): string {
        const managed = available.find(entry => entry.exec.indexOf("uwsm") !== -1);
        if (managed !== undefined)
            return managed.exec;

        return available.length > 0 ? available[0].exec : "";
    }

    function applyEnvironment(environment) {
        root.users = environment.users;
        root.fingerprint = environment.fingerprint === true;
        root.sessions = environment.sessions;
        if (root.username === "" && environment.users.length > 0)
            root.username = environment.users[0].name;

        if (root.sessionExec === "")
            root.sessionExec = root.preferredSession(environment.sessions);

        root.listed = true;
        if (root.fingerprint && root.canSubmit)
            root.scan(true);
    }

    // Greetd has ended the attempt already (or never began one).
    function fail(message: string) {
        root.password = "";
        root.busy = false;
        root.answering = false;
        root.fingerAttempt = false;
        root.queued = false;
        root.promptText = root.passwordPrompt;
        root.promptSecret = true;
        root.errorText = message;
    }

    // Another user while a question waits: that login is over. While the
    // reader has greetd, nothing ends it sooner; its end is left unused.
    onUsernameChanged: {
        if (root.answering) {
            Greetd.cancelSession();
            root.fail("");
        }
        if (root.scanning)
            root.autoScan = true;
    }
    onPasswordChanged: {
        if (root.password !== "")
            root.errorText = "";
    }
    Component.onCompleted: {
        if (!Greetd.available)
            root.errorText = "greetd is not running (no GREETD_SOCK)";
    }

    Connections {
        function onAuthMessage(message: string, error: bool, responseRequired: bool, echoResponse: bool) {
            if (!responseRequired) {
                if (message !== "") {
                    root.said = root.said.concat([message]);
                    // While it scans, the field's prompt says what to do.
                    if (!root.scanning)
                        root.errorText = root.said.join("\n");
                }
                return;
            }
            if (root.fingerAttempt) {
                // The password's question, answered with nothing: the
                // reader's turn. Any question after it is the user's.
                root.fingerAttempt = false;
                Greetd.respond("");
                return;
            }
            root.promptText = message;
            root.promptSecret = !echoResponse;
            if (root.password === "") {
                root.busy = false;
                root.answering = true;
                return;
            }
            const answer = root.password;
            root.password = "";
            Greetd.respond(answer);
        }

        function onAuthFailure(message: string) {
            if (root.scanning) {
                // No finger enrolled says nothing: to the user, Enter on an
                // empty field.
                root.scanFailed(root.said.length > 0 ? root.said.join("\n") : root.noPassword);
                return;
            }
            root.fail(root.said.length > 0 ? root.said.join("\n") : "Incorrect password");
        }

        function onError(error: string) {
            if (root.scanning) {
                root.scanFailed(error);
                return;
            }
            root.fail(error);
        }

        function onStateChanged() {
            root.sendQueued();
        }

        function onReadyToLaunch() {
            // A finger for the user picked before: not who is asked for now.
            // Quickshell takes greetd's answer to the cancel for whatever
            // login it has then, so a password entered meanwhile stays in
            // the field, for Enter, rather than going at once.
            if (Greetd.user !== root.username) {
                Greetd.cancelSession();
                if (!root.scanning) {
                    root.fail("");
                    return;
                }
                return;
            }
            const session = root.sessions.find(entry => entry.exec === root.sessionExec);
            if (session === undefined) {
                Greetd.cancelSession();
                root.fail("No session to start");
                return;
            }
            Greetd.launch(session.command, [], true);
        }

        // greetd starts the session once this compositor is gone, and
        // Quickshell quits by itself.
        function onLaunched() {
            Hyprland.dispatch("hl.dsp.exit()");
        }

        target: Greetd
    }

    Process {
        running: true
        command: ["python3", Quickshell.shellDir + "/greeter-env.py"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.applyEnvironment(JSON.parse(text));
                } catch (error) {
                    root.errorText = "Could not list users and sessions";
                }
            }
        }

        stderr: SplitParser {
            splitMarker: "\n"
            onRead: line => console.warn("greeter-env:", line)
        }
    }
}
