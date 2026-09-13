// notifications/Toasts.qml
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../services"
import "../style"

Scope {
    id: toastScope

    readonly property ShellScreen focusedScreen: {
        const monitor = Hyprland.focusedMonitor
        if (monitor === null) return null
        return Quickshell.screens.find(candidate => candidate.name === monitor.name) || null
    }

    readonly property var shown: NotificationService.popups.slice(0, Style.notifications.maxPopups)

    PanelWindow {
        id: window

        visible: toastScope.shown.length > 0
        screen: toastScope.focusedScreen

        WlrLayershell.namespace: "quickshell:toast-popup"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            right: true
        }
        margins {
            top: Style.popup.topMargin
            right: Style.bar.sideGap
        }

        implicitWidth: Style.notifications.width
        implicitHeight: Math.max(1, column.implicitHeight)
        exclusiveZone: 0
        color: Colors.base.panel

        Column {
            id: column

            width: parent.width
            spacing: Style.widgets.spacing

            Repeater {
                model: toastScope.shown

                delegate: Toast {
                    width: column.width
                }
            }
        }
    }
}
