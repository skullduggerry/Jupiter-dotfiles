import "../icons"
import "../services"
import "../style"
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

WlSessionLockSurface {
    id: root

    property bool engaged: false

    color: Colors.lock.background
    Component.onCompleted: passwordInput.forceActiveFocus()

    Image {
        id: wallpaper

        anchors.fill: parent
        // LockLook's choice; plain is the background colour alone.
        source: {
            const path = LockLook.lockBackground === "image" ? LockLook.lockImage : LockLook.lockBackground === "wallpaper" ? WallpaperService.current : "";
            return path !== "" ? "file://" + path : "";
        }
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }

    MultiEffect {
        id: background

        anchors.fill: parent
        source: wallpaper
        visible: wallpaper.status === Image.Ready
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: Style.lock.blurMax
        blur: LockLook.blurFor(root.engaged)

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
        id: column

        anchors.centerIn: parent
        spacing: Style.lock.spacing

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: LockLook.clock
            text: Time.time
            color: Colors.lock.text
            font.family: Style.text.font
            font.pixelSize: Style.text.displaySize
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: LockLook.clock
            text: Time.date
            color: Colors.lock.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }

        Rectangle {
            id: field

            anchors.horizontalCenter: parent.horizontalCenter
            width: Style.lock.fieldWidth
            height: Style.lock.fieldHeight
            radius: Style.lock.fieldRadius
            color: "transparent"
            border.width: Style.border.width
            border.color: LockService.authenticating ? Colors.lock.busy : Colors.lock.fieldBorder

            // Inside the border, the desktop's glass (LockLook.glass): the
            // wallpaper behind the field, frosted, under the field's tint.
            ClippingRectangle {
                id: frost

                anchors.fill: parent
                anchors.margins: field.border.width
                visible: LockLook.glass && wallpaper.status === Image.Ready
                radius: field.radius - field.border.width
                color: "transparent"

                MultiEffect {
                    x: -(column.x + field.x + frost.x)
                    y: -(column.y + field.y + frost.y)
                    width: background.width
                    height: background.height
                    source: wallpaper
                    autoPaddingEnabled: false
                    blurEnabled: true
                    blurMax: Style.lock.blurMax
                    blur: Style.lock.blurAmount
                }
            }

            Rectangle {
                anchors.fill: frost
                radius: frost.radius
                color: Colors.lock.field
            }

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
                echoMode: LockService.promptVisible ? TextInput.Normal : TextInput.Password
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
                    text: LockService.authenticating ? "Checking…" : LockService.prompt !== "" ? LockService.prompt : LockService.fingerprint ? "Password or fingerprint" : "Password"
                    textFormat: Text.PlainText
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
            textFormat: Text.PlainText
            color: Colors.status.error
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
    }

    Text {
        text: Quickshell.env("USER")
        textFormat: Text.PlainText
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
