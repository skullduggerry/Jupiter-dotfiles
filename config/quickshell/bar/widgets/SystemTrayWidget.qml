// bar/widgets/SystemTrayWidget.qml
import QtQuick
import QtQuick.Window
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../style"

Item {
    id: root

    visible: SystemTray.items.count > 0
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: Style.bar.height

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Style.widgets.spacing

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayIcon
                required property SystemTrayItem modelData

                width: Style.bar.height - 12
                height: width

                IconImage {
                    anchors.fill: parent
                    source: trayIcon.modelData.icon
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        const pos = trayIcon.mapToItem(null, mouse.x, mouse.y)
                        const wantsMenu = mouse.button === Qt.RightButton || trayIcon.modelData.onlyMenu
                        if (wantsMenu && trayIcon.modelData.hasMenu) {
                            trayIcon.modelData.display(trayIcon.Window.window, pos.x, pos.y)
                        } else if (!trayIcon.modelData.onlyMenu) {
                            trayIcon.modelData.activate()
                        }
                    }
                }
            }
        }
    }
}
