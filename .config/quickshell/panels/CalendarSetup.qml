import "../icons"
import "../services"
import "../style"
import QtQuick

Column {
    id: root

    property string error: ""

    function submit() {
        root.error = CalendarService.configure(addressField.text, userField.text);
        if (root.error !== "")
            return;

        // show what was actually kept, which is the base address rather than
        // the web-UI page people paste in
        addressField.text = CalendarService.serverUrl;
        userField.text = CalendarService.user;
    }

    function signIn() {
        root.error = CalendarService.signIn(addressField.text);
        if (root.error === "")
            addressField.text = CalendarService.serverUrl;
    }

    spacing: Style.widgets.spacing
    Component.onCompleted: {
        addressField.text = CalendarService.serverUrl;
        userField.text = CalendarService.user;
    }

    Connections {
        function onUserChanged() {
            userField.text = CalendarService.user;
        }

        target: CalendarService
    }

    InputField {
        id: addressField

        width: parent.width
        icon: Icons.globe
        placeholder: "https://cloud.example.org"
        onAccepted: root.signIn()
    }

    InputField {
        id: userField

        width: parent.width
        icon: Icons.user
        placeholder: "user (filled in by signing in)"
        onAccepted: root.submit()
    }

    Rectangle {
        width: parent.width
        height: Style.popup.itemHeight
        radius: Style.popup.rowRadius
        color: signInArea.containsMouse ? Colors.base.hover : "transparent"
        border.width: Style.border.width
        border.color: Colors.icon.active

        Text {
            anchors.centerIn: parent
            text: CalendarService.signingIn ? "Waiting for the browser…" : "Sign in with your browser"
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }

        MouseArea {
            id: signInArea

            anchors.fill: parent
            hoverEnabled: true
            enabled: !CalendarService.signingIn
            onClicked: root.signIn()
        }
    }

    Text {
        width: parent.width
        text: {
            if (root.error !== "")
                return root.error;

            if (CalendarService.loginMessage !== "")
                return CalendarService.loginMessage;

            return "Paste any page of your Nextcloud, then sign in — the browser handles SSO and the server sends back an app password. Filling the user in by hand works too, if you made an app password yourself.";
        }
        color: root.error !== "" ? Colors.status.error : Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
        wrapMode: Text.Wrap
    }
}
