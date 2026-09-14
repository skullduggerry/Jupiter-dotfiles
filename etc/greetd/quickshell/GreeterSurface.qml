import "."
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
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
        source: "file://" + Quickshell.shellDir + "/wallpaper.jpg"
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
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.displaySize
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "ddd d MMM")
            color: Colors.text.muted
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
                    required property var modelData

                    label: modelData.display
                    selected: modelData.name === GreeterService.username
                    onChosen: GreeterService.username = modelData.name
                }

            }

        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Style.lock.fieldWidth
            height: Style.lock.fieldHeight
            radius: Style.lock.fieldRadius
            color: Colors.lock.field
            border.width: Style.border.width
            border.color: GreeterService.busy ? Colors.lock.busy : Colors.lock.fieldBorder

            Text {
                id: fieldIcon

                text: GreeterService.busy ? "󰔟" : "󰌾"
                color: GreeterService.busy ? Colors.lock.busy : Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.iconSize

                anchors {
                    left: parent.left
                    leftMargin: Style.bar.padding
                    verticalCenter: parent.verticalCenter
                }

            }

            TextInput {
                id: passwordInput

                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size
                echoMode: TextInput.Password
                passwordCharacter: "●"
                readOnly: GreeterService.busy
                clip: true
                Keys.onPressed: (event) => {
                    root.engaged = true;
                }
                onTextChanged: GreeterService.password = passwordInput.text
                onAccepted: GreeterService.submit()

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
                    value: GreeterService.password
                }

                Text {
                    anchors.fill: parent
                    visible: passwordInput.text === ""
                    text: GreeterService.busy ? "Checking…" : GreeterService.promptText
                    color: Colors.text.muted
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
                    required property var modelData

                    label: modelData.name
                    selected: modelData.exec === GreeterService.sessionExec
                    onChosen: GreeterService.sessionExec = modelData.exec
                }

            }

        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Style.lock.fieldWidth
            text: GreeterService.errorText
            color: Colors.status.error
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

    }

}
