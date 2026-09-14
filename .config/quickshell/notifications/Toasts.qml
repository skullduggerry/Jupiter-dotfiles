// notifications/Toasts.qml
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
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

    property var deadlines: ({})

    function popupTimeout(notification: Notification): int {
        if (notification.urgency === NotificationUrgency.Critical) return 0
        if (notification.expireTimeout > 0) return notification.expireTimeout
        return Style.notifications.timeout
    }

    function remainingTimeout(notification: Notification): int {
        let deadline = toastScope.deadlines[notification.id]
        if (deadline === undefined) {
            const full = toastScope.popupTimeout(notification)
            deadline = full > 0 ? Date.now() + full : 0
            toastScope.deadlines[notification.id] = deadline
        }
        if (deadline === 0) return 0
        return Math.max(1, deadline - Date.now())
    }

    onShownChanged: {
        const live = ({})
        for (let index = 0; index < toastScope.shown.length; index++) {
            const id = toastScope.shown[index].id
            const deadline = toastScope.deadlines[id]
            if (deadline !== undefined) live[id] = deadline
        }
        toastScope.deadlines = live
    }

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
                    timeout: toastScope.remainingTimeout(modelData)
                }
            }
        }
    }
}
