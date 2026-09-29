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

        Text {
            text: NotificationService.doNotDisturb ? "\u{F009B}" : NotificationService.count > 0 ? "\u{F009A}" : "\u{F009C}"
            color: !NotificationService.doNotDisturb && NotificationService.hasCritical ? Colors.notification.urgent : Colors.icon.active
            font.family: Style.text.font
            font.pixelSize: Style.text.iconSize
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
                notificationPopup.visible = !notificationPopup.visible;
        }
    }

    // Deliberately not anchored to the bell, which moves with the bar's
    // drawer: the centre opens at the right edge, exactly the column the
    // toasts pop up in, so a notification is found where it was shown.
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
