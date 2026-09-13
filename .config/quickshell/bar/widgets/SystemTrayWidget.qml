// bar/widgets/SystemTrayWidget.qml
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../style"

Item {
    id: root

    required property ShellScreen screen

    readonly property var hiddenIds: ["nm-applet", "blueman"]

    readonly property var items: SystemTray.items.values.filter(item => !root.hiddenIds.includes(item.id))

    visible: root.items.length > 0
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: Style.bar.height

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Style.widgets.spacing

        Repeater {
            model: root.items

            delegate: Rectangle {
                id: trayIcon
                required property SystemTrayItem modelData

                function open() {
                    if (trayIcon.modelData.hasMenu) trayMenu.openAt(trayIcon.modelData.menu, trayIcon)
                    else trayIcon.modelData.secondaryActivate()
                }

                implicitWidth: Style.widgets.iconSize + Style.tray.itemPadding * 2
                implicitHeight: trayIcon.implicitWidth
                radius: Style.popup.rowRadius
                color: area.containsMouse ? Colors.base.hover : "transparent"

                IconImage {
                    id: icon
                    anchors.centerIn: parent
                    implicitSize: Style.widgets.iconSize
                    source: trayIcon.modelData.icon
                    visible: false
                }

                MultiEffect {
                    anchors.fill: icon
                    source: icon
                    saturation: trayIcon.modelData.status === Status.NeedsAttention ? 0 : Style.tray.saturation
                    opacity: trayIcon.modelData.status === Status.Passive ? Style.tray.passiveOpacity : 1
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.MiddleButton) trayIcon.modelData.secondaryActivate()
                        else if (mouse.button === Qt.RightButton || trayIcon.modelData.onlyMenu) trayIcon.open()
                        else trayIcon.modelData.activate()
                    }
                    onWheel: (wheel) => trayIcon.modelData.scroll(wheel.angleDelta.y, false)
                }
            }
        }
    }

    TrayMenu {
        id: trayMenu
        screen: root.screen
    }
}
