// bar/widgets/PowerWidget.qml
//
// Session actions menu. Lock shells out to an external lock utility
// (hyprlock by default) since this project doesn't have a native
// Quickshell lock screen yet (see TODO.md Phase 4); swap the command
// below if you use swaylock or another locker instead.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../style"

Item {
    id: root

    required property ShellScreen screen

    implicitWidth: icon.implicitWidth + Style.widgets.padding * 2
    implicitHeight: Style.bar.height

    Text {
        id: icon
        anchors.centerIn: parent
        text: "⏻"
        color: Colors.power.normal
        font.family: Style.text.font
        font.pixelSize: Style.text.iconSize
    }

    MouseArea {
        anchors.fill: parent
        onClicked: powerPopup.visible = !powerPopup.visible
    }

    WidgetPopup {
        id: powerPopup
        screen: root.screen
        namespaceSuffix: "power-popup"
        popupWidth: Style.popup.width
        popupHeight: actions.implicitHeight + Style.bar.padding * 2

        Column {
            id: actions
            anchors.fill: parent
            anchors.margins: Style.bar.padding
            spacing: Style.widgets.spacing

            PowerAction {
                label: "Lock"
                onActivated: {
                    Quickshell.execDetached(["hyprlock"])
                    powerPopup.visible = false
                }
            }
            PowerAction {
                label: "Logout"
                onActivated: {
                    Hyprland.dispatch("exit")
                    powerPopup.visible = false
                }
            }
            PowerAction {
                label: "Suspend"
                onActivated: {
                    Quickshell.execDetached(["systemctl", "suspend"])
                    powerPopup.visible = false
                }
            }
            PowerAction {
                label: "Reboot"
                labelColor: Colors.power.danger
                onActivated: {
                    Quickshell.execDetached(["systemctl", "reboot"])
                    powerPopup.visible = false
                }
            }
            PowerAction {
                label: "Shutdown"
                labelColor: Colors.power.danger
                onActivated: {
                    Quickshell.execDetached(["systemctl", "poweroff"])
                    powerPopup.visible = false
                }
            }
        }
    }
}
