import "."
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "style"

PanelWindow {
    id: root

    required property ShellScreen modelData
    property bool engaged: false

    screen: root.modelData
    color: Colors.lock.background
    WlrLayershell.namespace: "quickshell:greeter"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    Component.onCompleted: passwordInput.forceActiveFocus()

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Image {
        id: wallpaper

        anchors.fill: parent
        source: LockLook.loginBackground === "plain" ? "" : "file://" + Quickshell.shellDir + "/wallpaper.jpg"
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
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Colors.lock.text
            font.family: Style.text.font
            font.pixelSize: Style.text.displaySize
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: LockLook.clock
            text: Qt.formatDateTime(clock.date, "ddd d MMM")
            color: Colors.lock.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }

        Flow {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Style.lock.fieldWidth
            spacing: Style.widgets.spacing

            Repeater {
                model: GreeterService.users

                delegate: GreeterChoice {
                    id: user

                    required property var modelData

                    label: user.modelData.display
                    selected: user.modelData.name === GreeterService.username
                    onChosen: GreeterService.username = user.modelData.name
                }
            }
        }

        Rectangle {
            id: field

            anchors.horizontalCenter: parent.horizontalCenter
            width: Style.lock.fieldWidth
            height: Style.lock.fieldHeight
            radius: Style.lock.fieldRadius
            color: "transparent"
            border.width: Style.border.width
            border.color: GreeterService.busy ? Colors.lock.busy : Colors.lock.fieldBorder

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

            TextInput {
                id: passwordInput

                color: Colors.lock.text
                font.family: Style.text.font
                font.pixelSize: Style.text.size
                echoMode: GreeterService.promptSecret ? TextInput.Password : TextInput.Normal
                passwordCharacter: "●"
                readOnly: GreeterService.busy
                clip: true
                Keys.onPressed: event => {
                    root.engaged = true;
                }
                onTextChanged: GreeterService.password = passwordInput.text
                onAccepted: GreeterService.submit()

                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: Style.bar.padding
                    rightMargin: Style.bar.padding
                    verticalCenter: parent.verticalCenter
                }

                Binding {
                    target: passwordInput
                    property: "text"
                    value: GreeterService.password
                }

                Text {
                    anchors.fill: parent
                    visible: passwordInput.text === ""
                    text: GreeterService.busy ? "Checking…" : GreeterService.scanning ? GreeterService.scanPrompt : GreeterService.promptText
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

        Flow {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Style.lock.fieldWidth
            spacing: Style.widgets.spacing

            Repeater {
                model: GreeterService.sessions

                delegate: GreeterChoice {
                    id: session

                    required property var modelData

                    label: session.modelData.name
                    selected: session.modelData.exec === GreeterService.sessionExec
                    onChosen: GreeterService.sessionExec = session.modelData.exec
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Style.lock.fieldWidth
            text: GreeterService.errorText
            textFormat: Text.PlainText
            color: Colors.status.error
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
    }
}
