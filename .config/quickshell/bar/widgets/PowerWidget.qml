import "../../services"
import "../../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    required property ShellScreen screen

    implicitWidth: icon.implicitWidth + Style.widgets.padding * 2
    implicitHeight: Style.bar.height

    Text {
        id: icon

        anchors.centerIn: parent
        text: "⏻"
        color: Colors.icon.active
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
                    powerPopup.visible = false;
                    LockService.lock();
                }
            }

            PowerAction {
                label: "Logout"
                onActivated: {
                    powerPopup.visible = false;
                    Hyprland.dispatch("hl.dsp.exit()");
                }
            }

            PowerAction {
                label: "Suspend"
                onActivated: {
                    powerPopup.visible = false;
                    Quickshell.execDetached(["systemctl", "suspend"]);
                }
            }

            PowerAction {
                label: "Reboot"
                labelColor: Colors.power.danger
                onActivated: {
                    powerPopup.visible = false;
                    Quickshell.execDetached(["systemctl", "reboot"]);
                }
            }

            PowerAction {
                label: "Shutdown"
                labelColor: Colors.power.danger
                onActivated: {
                    powerPopup.visible = false;
                    Quickshell.execDetached(["systemctl", "poweroff"]);
                }
            }
        }
    }
}
