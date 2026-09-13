// bar/widgets/NotificationWidget.qml
import QtQuick
import Quickshell
import "../../panels"
import "../../services"
import "../../style"

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
            text: NotificationService.doNotDisturb ? "\uf1f6" : "\uf0f3"
            color: NotificationService.doNotDisturb ? Colors.text.muted
                : NotificationService.hasCritical ? Colors.notification.urgent
                : NotificationService.count > 0 ? Colors.notification.badge
                : Colors.text.base
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
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) NotificationService.doNotDisturb = !NotificationService.doNotDisturb
            else notificationPopup.visible = !notificationPopup.visible
        }
    }

    WidgetPopup {
        id: notificationPopup
        screen: root.screen
        anchorItem: root
        namespaceSuffix: "notifications-popup"
        popupWidth: Style.dropdown.width
        popupHeight: Math.max(Style.popup.minHeight,
                              Math.min(Style.dropdown.maxHeight,
                                       panel.item ? panel.item.preferredHeight : Style.popup.minHeight))

        Loader {
            id: panel
            anchors.fill: parent
            active: notificationPopup.visible

            sourceComponent: NotificationPanel {}
        }
    }
}
