pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    property var users: []
    property var sessions: []
    property string username: ""
    property string sessionExec: ""
    property string password: ""
    property string errorText: ""
    property string promptText: "Password"
    property bool ready: false
    property bool busy: false
    readonly property bool canSubmit: root.ready && !root.busy && root.username !== "" && root.sessionExec !== ""

    function send(command) {
        auth.write(JSON.stringify(command) + "\n");
    }

    function submit() {
        if (!root.canSubmit || root.password === "")
            return ;

        root.errorText = "";
        root.busy = true;
        root.send({
            "cmd": "login",
            "username": root.username
        });
    }

    function preferredSession(available) : string {
        const managed = available.find((entry) => {
            return entry.exec.indexOf("uwsm") !== -1;
        });
        if (managed !== undefined)
            return managed.exec;

        return available.length > 0 ? available[0].exec : "";
    }

    function applyEnvironment(event) {
        root.users = event.users;
        root.sessions = event.sessions;
        if (root.username === "" && event.users.length > 0)
            root.username = event.users[0].name;

        if (root.sessionExec === "")
            root.sessionExec = root.preferredSession(event.sessions);

        root.ready = true;
    }

    function fail(message) {
        root.password = "";
        root.busy = false;
        root.send({
            "cmd": "cancel"
        });
        root.errorText = message;
    }

    function handle(event) {
        if (event.type === "env") {
            root.applyEnvironment(event);
        } else if (event.type === "prompt") {
            root.promptText = event.message;
            if (root.password === "") {
                root.busy = false;
                return ;
            }
            const answer = root.password;
            root.password = "";
            root.send({
                "cmd": "password",
                "response": answer
            });
        } else if (event.type === "info") {
            root.errorText = event.message;
        } else if (event.type === "authed") {
            root.send({
                "cmd": "start",
                "exec": root.sessionExec
            });
        } else if (event.type === "started") {
            Hyprland.dispatch("hl.dsp.exit()");
            Qt.quit();
        } else if (event.type === "error") {
            root.fail(event.message);
        } else if (event.type === "fatal") {
            root.busy = false;
            root.errorText = event.message;
        }
    }

    onPasswordChanged: {
        if (root.password !== "")
            root.errorText = "";

    }

    Process {
        id: auth

        running: true
        stdinEnabled: true
        command: ["python3", Quickshell.shellDir + "/greetd-auth.py"]
        onExited: (exitCode, exitStatus) => {
            root.busy = false;
            root.ready = false;
            root.errorText = "Authentication helper exited (" + exitCode + ")";
        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                return root.handle(JSON.parse(line));
            }
        }

        stderr: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                return console.warn("greetd-auth:", line);
            }
        }

    }

}
