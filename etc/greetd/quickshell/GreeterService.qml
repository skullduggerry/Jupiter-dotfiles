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
    property string username: ""
    property string sessionExec: ""
    property string password: ""
    property string errorText: ""
    property string promptText: "Password"
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
        if (!root.canSubmit || root.password === "")
            return;

        root.errorText = "";
        root.busy = true;
        if (root.answering) {
            const answer = root.password;
            root.password = "";
            root.answering = false;
            Greetd.respond(answer);
            return;
        }
        root.said = [];
        Greetd.createSession(root.username);
    }

    function preferredSession(available): string {
        const managed = available.find(entry => entry.exec.indexOf("uwsm") !== -1);
        if (managed !== undefined)
            return managed.exec;

        return available.length > 0 ? available[0].exec : "";
    }

    function applyEnvironment(environment) {
        root.users = environment.users;
        root.sessions = environment.sessions;
        if (root.username === "" && environment.users.length > 0)
            root.username = environment.users[0].name;

        if (root.sessionExec === "")
            root.sessionExec = root.preferredSession(environment.sessions);

        root.listed = true;
    }

    // Greetd has ended the attempt already (or never began one).
    function fail(message: string) {
        root.password = "";
        root.busy = false;
        root.answering = false;
        root.promptText = "Password";
        root.promptSecret = true;
        root.errorText = message;
    }

    // Another user while a question waits: that login is over.
    onUsernameChanged: {
        if (root.answering) {
            Greetd.cancelSession();
            root.fail("");
        }
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
                    root.errorText = root.said.join("\n");
                }
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
            root.fail(root.said.length > 0 ? root.said.join("\n") : "Incorrect password");
        }

        function onError(error: string) {
            root.fail(error);
        }

        function onReadyToLaunch() {
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
