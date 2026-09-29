pragma ComponentBehavior: Bound

import "../services"
import "../style"
import QtQuick

PanelFrame {
    id: root

    implicitHeight: root.chromeHeight + Math.max(Style.popup.itemHeight, entries.contentHeight)

    title: "Notifications"
    // Toasts give way to an open centre; see NotificationService.viewers.
    Component.onCompleted: NotificationService.viewers += 1
    Component.onDestruction: NotificationService.viewers -= 1

    ListView {
        id: entries

        anchors.fill: parent
        clip: true
        spacing: Style.bar.spacing
        model: NotificationService.list

        delegate: NotificationEntry {
            width: entries.width
        }
    }

    Text {
        anchors.centerIn: entries
        visible: entries.count === 0
        text: NotificationService.doNotDisturb ? "Do not disturb" : "No notifications"
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.size
    }

    trailing: TextButton {
        id: clearAll

        visible: NotificationService.count > 0
        text: clearAll.hovered ? "Clear all" : NotificationService.count
        onClicked: NotificationService.dismissAll()
    }
}
