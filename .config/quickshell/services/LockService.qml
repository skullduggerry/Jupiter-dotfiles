pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pam

Singleton {
    id: root

    property alias locked: lockState.locked
    property string password: ""
    property string errorText: ""
    readonly property bool authenticating: pam.active
    readonly property string pamConfig: "login"

    function lock() {
        if (root.locked)
            return;

        root.password = "";
        root.errorText = "";
        root.locked = true;
    }

    function submit() {
        if (pam.active || root.password === "")
            return;

        root.errorText = "";
        pam.start();
    }

    onPasswordChanged: {
        if (root.password !== "")
            root.errorText = "";
    }

    PersistentProperties {
        id: lockState

        property bool locked: false

        reloadableId: "lockState"
    }

    PamContext {
        id: pam

        config: root.pamConfig
        onPamMessage: {
            if (pam.responseRequired)
                pam.respond(root.password);
            else if (pam.message !== "")
                root.errorText = pam.message;
        }
        onCompleted: result => {
            root.password = "";
            if (result === PamResult.Success) {
                root.errorText = "";
                root.locked = false;
                return;
            }
            root.errorText = result === PamResult.MaxTries ? "Too many attempts" : "Incorrect password";
        }
        onError: error => {
            root.password = "";
            root.errorText = "PAM: " + PamError.toString(error);
        }
    }
}
