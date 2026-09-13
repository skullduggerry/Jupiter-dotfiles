// lock/LockSurface.qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"
import "../style"

WlSessionLockSurface {
    id: root

    color: Colors.lock.background

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
                passwordCharacter: "●"
                readOnly: LockService.authenticating
                clip: true

                onTextChanged: LockService.password = passwordInput.text
                onAccepted: LockService.submit()

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
