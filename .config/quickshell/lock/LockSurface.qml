import "../icons"
import "../services"
import "../style"
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

WlSessionLockSurface {
    id: root

    property bool engaged: false

    color: Colors.lock.background
    Component.onCompleted: passwordInput.forceActiveFocus()

    Image {
        id: wallpaper

        anchors.fill: parent
        source: WallpaperService.current !== "" ? "file://" + WallpaperService.current : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        visible: wallpaper.status === Image.Ready
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: Style.lock.blurMax
        blur: root.engaged ? Style.lock.blurAmount : 0

        Behavior on blur {
            NumberAnimation {
                duration: Style.animation.slow
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.lock.scrim
    }

    Column {
        anchors.centerIn: parent
        spacing: Style.lock.spacing

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.time
            color: Colors.lock.text
            font.family: Style.text.font
            font.pixelSize: Style.text.displaySize
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.date
            color: Colors.lock.muted
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

            Icon {
                id: fieldIcon

                text: LockService.authenticating ? Icons.hourglass : Icons.lock
                color: LockService.authenticating ? Colors.lock.busy : Colors.lock.muted

                anchors {
                    left: parent.left
                    leftMargin: Style.bar.padding
                    verticalCenter: parent.verticalCenter
                }
            }

            TextInput {
                id: passwordInput

                color: Colors.lock.text
                font.family: Style.text.font
                font.pixelSize: Style.text.size
                echoMode: TextInput.Password
                passwordCharacter: "●"
                readOnly: LockService.authenticating
                clip: true
                Keys.onPressed: event => {
                    root.engaged = true;
                }
                onTextChanged: LockService.password = passwordInput.text
                onAccepted: LockService.submit()

                anchors {
                    left: fieldIcon.right
                    right: parent.right
                    leftMargin: Style.widgets.spacing
                    rightMargin: Style.bar.padding
                    verticalCenter: parent.verticalCenter
                }

                Binding {
                    target: passwordInput
                    property: "text"
                    value: LockService.password
                }

                Text {
                    anchors.fill: parent
                    visible: passwordInput.text === ""
                    text: LockService.authenticating ? "Checking…" : "Password"
                    color: Colors.lock.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: Style.animation.normal
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
        text: Quickshell.env("USER")
        color: Colors.lock.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize

        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: Style.bar.padding * 2
        }
    }
}
