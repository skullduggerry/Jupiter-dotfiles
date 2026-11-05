pragma ComponentBehavior: Bound

import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland

Scope {
    id: toastScope

    readonly property var shown: NotificationService.popups.slice(0, Style.notifications.maxPopups)
    property var deadlines: ({})

    function popupTimeout(notification: Notification): int {
        if (notification.urgency === NotificationUrgency.Critical)
            return 0;

        if (notification.expireTimeout > 0)
            return notification.expireTimeout;

        return Style.notifications.timeout;
    }

    function remainingTimeout(notification: Notification): int {
        let deadline = toastScope.deadlines[notification.id];
        if (deadline === undefined) {
            const full = toastScope.popupTimeout(notification);
            deadline = full > 0 ? Date.now() + full : 0;
            toastScope.deadlines[notification.id] = deadline;
        }
        if (deadline === 0)
            return 0;

        return Math.max(1, deadline - Date.now());
    }

    onShownChanged: {
        const live = ({});
        for (let index = 0; index < toastScope.shown.length; index++) {
            const id = toastScope.shown[index].id;
            const deadline = toastScope.deadlines[id];
            if (deadline !== undefined)
                live[id] = deadline;
        }
        toastScope.deadlines = live;
    }

    PanelWindow {
        id: window

        // The toasts' column, and how far down a popup open across it reaches:
        // the toasts move below it rather than lie over it (PopupAreas).
        readonly property real columnRight: window.screen !== null ? window.screen.width - WindowGaps.right : 0
        readonly property real coveredTo: PopupAreas.bottomOver(window.screen !== null ? window.screen.name : "", window.columnRight - window.implicitWidth, window.columnRight)

        visible: toastScope.shown.length > 0
        screen: Screens.focused
        WlrLayershell.namespace: "quickshell:toast-popup"
        WlrLayershell.layer: WlrLayer.Overlay
        // Keyboard focus only under the pointer, for a reply field. Hyprland
        // hands the keyboard to a layer that maps with on-demand focus, so a
        // toast appearing, or following focus to another monitor, would take
        // it from the app in use and close an open dropdown.
        WlrLayershell.keyboardFocus: hover.hovered ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        implicitWidth: Style.notifications.width
        implicitHeight: Math.max(1, column.implicitHeight)
        exclusiveZone: 0
        color: Colors.base.panel
        // Following focus to another monitor, the stack fades in there rather
        // than appearing at once.
        onScreenChanged: arrival.restart()

        anchors {
            top: true
            right: true
        }

        margins {
            top: Math.max(WindowGaps.top, window.coveredTo + Style.bar.spacing)
            right: WindowGaps.right
        }

        NumberAnimation {
            id: arrival

            target: column
            property: "opacity"
            from: 0
            to: 1
            duration: Style.animation.slow
            easing.type: Easing.OutCubic
        }

        Column {
            id: column

            width: parent.width
            spacing: Style.widgets.spacing

            HoverHandler {
                id: hover
            }

            Repeater {
                model: toastScope.shown

                delegate: Toast {
                    width: column.width
                    alone: toastScope.shown.length === 1
                    timeout: toastScope.remainingTimeout(modelData)
                }
            }
        }
    }
}
