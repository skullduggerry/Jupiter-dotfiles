// lock/LockSurface.qml
//
// One monitor's lock surface: the clock, the password field, and whatever
// PAM had to say about the last attempt. Lock.qml instantiates one of these
// per screen; they all read and write the same buffer in LockService, so
// typing on either monitor shows up on both.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"
import "../style"

WlSessionLockSurface {
    id: root

    color: Colors.lock.background

    // Nothing else on the surface competes for the keyboard, so the field
    // takes focus as soon as the compositor hands this surface the input it
    // reserves for a lock.
    Component.onCompleted: passwordInput.forceActiveFocus()

    Column {
        anchors.centerIn: parent
        spacing: Style.lock.spacing

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.time
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.displaySize
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.date
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Style.lock.fieldWidth
            height: Style.lock.fieldHeight
            radius: Style.lock.fieldRadius
            color: Colors.lock.field
            border.width: Style.border.width
            border.color: LockService.authenticating ? Colors.lock.busy : Colors.lock.fieldBorder

            Behavior on border.color {
                ColorAnimation { duration: Style.animation.normal }
            }

            Text {
                id: fieldIcon
                anchors {
                    left: parent.left
                    leftMargin: Style.bar.padding
                    verticalCenter: parent.verticalCenter
                }
                text: LockService.authenticating ? "󰔟" : "󰌾"
                color: LockService.authenticating ? Colors.lock.busy : Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.iconSize
            }

            TextInput {
                id: passwordInput

                anchors {
                    left: fieldIcon.right
                    right: parent.right
                    leftMargin: Style.widgets.spacing
                    rightMargin: Style.bar.padding
                    verticalCenter: parent.verticalCenter
                }
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size
                echoMode: TextInput.Password
                // Wider than the font's own asterisk, and the same mark the
                // dots under a calendar day use.
                passwordCharacter: "●"
                // PAM already has this attempt; letting it be edited would
                // only change a buffer that has been sent.
                readOnly: LockService.authenticating
                clip: true

                onTextChanged: LockService.password = passwordInput.text
                onAccepted: LockService.submit()

                // The other monitor's field is the same buffer. A Binding
                // rather than a plain `text:` assignment because typing here
                // writes to `text` directly, which would break an ordinary
                // binding the first time a key was pressed.
                Binding {
                    target: passwordInput
                    property: "text"
                    value: LockService.password
                }

                Text {
                    anchors.fill: parent
                    visible: passwordInput.text === ""
                    text: LockService.authenticating ? "Checking…" : "Password"
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // Reserves its line whether or not there's a failure to report, so
        // the field doesn't jump up the screen between attempts.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Style.lock.fieldWidth
            text: LockService.errorText
            color: Colors.status.error
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
    }

    // Who the password belongs to, in the corner rather than the middle:
    // useful on a shared machine, noise in the centre of the screen.
    Text {
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: Style.bar.padding * 2
        }
        text: Quickshell.env("USER")
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
    }
}
