import "../../icons"
import "../../panels"
import "../../services"
import "../../style"
import QtQuick
import Quickshell

Item {
    id: root

    required property ShellScreen screen

    implicitWidth: row.implicitWidth + Style.widgets.padding * 2
    implicitHeight: Style.bar.height

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Style.widgets.spacing

        Icon {
            text: NotificationService.doNotDisturb ? Icons.bellOff : NotificationService.count > 0 ? Icons.bellDot : Icons.bell
            color: !NotificationService.doNotDisturb && NotificationService.hasCritical ? Colors.notification.urgent : Colors.icon.active
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: NotificationService.count > 0
            text: NotificationService.count
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                NotificationService.doNotDisturb = !NotificationService.doNotDisturb;
            else
                notificationPopup.open = !notificationPopup.open;
        }
    }

    // SUPER+N, on the focused screen's bar.
    Connections {
        function onToggleRequested() {
            if (root.screen === Screens.focused)
                notificationPopup.open = !notificationPopup.open;
        }

        target: NotificationService
    }

    // Deliberately not anchored to the bell, which moves with the bar's
    // drawer: the centre opens at the right edge, exactly the column the
    // toasts pop up in, so a notification is found where it was shown. From
    // a small bar it opens under the pill, as everything there does.
    WidgetPopup {
        id: notificationPopup

        screen: root.screen
        namespaceSuffix: "notifications-popup"
        popupWidth: Style.notifications.width
        popupHeight: Math.max(Style.popup.minHeight, Math.min(Style.dropdown.maxHeight, panel.implicitHeight))

        Loader {
            id: panel

            anchors.fill: parent
            active: notificationPopup.visible

            sourceComponent: NotificationPanel {}
        }
    }
}
