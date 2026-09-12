// bar/widgets/SystemTrayWidget.qml
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../style"

Item {
    id: root

    // Quickshell's ObjectModel exposes its contents as `values` (a JS list);
    // it has no `count`/`get()` the way a QML ListModel does. Reading a
    // nonexistent `count` silently yielded `undefined`, so this widget used
    // to evaluate `undefined > 0` and hide itself permanently.
    readonly property int itemCount: SystemTray.items.values.length

    visible: itemCount > 0
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

                implicitWidth: Style.widgets.iconSize
                implicitHeight: Style.widgets.iconSize

                // Opens the item's DBusMenu just below the icon. `display()`
                // wants the Quickshell window (QsWindow.window), not the
                // underlying QQuickWindow, and coordinates relative to it,
                // which QsWindow.itemRect() already reports.
                function showMenu() {
                    const rect = trayIcon.QsWindow.itemRect(trayIcon)
                    trayIcon.modelData.display(trayIcon.QsWindow.window, rect.x, rect.y + rect.height)
                }

                IconImage {
                    anchors.fill: parent
                    // Without an explicit size the Image briefly has none, so
                    // sourceSize is 0x0 and Qt rasterizes themed SVG icons at
                    // their natural size — which logs a flood of
                    // "qt.svg.draw: The requested buffer size is too big".
                    implicitSize: Style.widgets.iconSize
                    source: trayIcon.modelData.icon
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.MiddleButton) {
                            trayIcon.modelData.secondaryActivate()
                        } else if (mouse.button === Qt.RightButton) {
                            if (trayIcon.modelData.hasMenu) trayIcon.showMenu()
                            else trayIcon.modelData.secondaryActivate()
                        } else if (trayIcon.modelData.onlyMenu) {
                            if (trayIcon.modelData.hasMenu) trayIcon.showMenu()
                        } else {
                            trayIcon.modelData.activate()
                        }
                    }
                }
            }
        }
    }
}
