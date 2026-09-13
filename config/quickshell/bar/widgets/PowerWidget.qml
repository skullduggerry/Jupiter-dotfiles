// bar/widgets/PowerWidget.qml
//
// Session actions menu. "Lock" raises the shell's own lock surface through
// LockService rather than spawning hyprlock — see lock/Lock.qml.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../services"
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
        anchorItem: root
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
                    powerPopup.visible = false
                    LockService.lock()
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
