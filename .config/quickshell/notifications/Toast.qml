// notifications/Toast.qml
import QtQuick
import Quickshell.Services.Notifications
import "../panels"
import "../services"
import "../style"

Rectangle {
    id: root

    required property Notification modelData

    readonly property int notificationId: root.modelData.id
    readonly property bool urgent: root.modelData.urgency === NotificationUrgency.Critical

    required property int timeout

    implicitHeight: entry.implicitHeight + Style.bar.padding * 2
    radius: Style.bar.radius
    color: Colors.base.surface
    border.width: Style.border.width
    border.color: root.urgent ? Colors.notification.urgent : Colors.base.border

    Timer {
        running: root.timeout > 0
        interval: root.timeout
        onTriggered: NotificationService.expirePopup(root.modelData)
    }

    NotificationEntry {
        id: entry
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Style.bar.padding
        }
        modelData: root.modelData
        onDismissed: NotificationService.hidePopup(root.notificationId)
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: NotificationService.hidePopup(root.notificationId)
    }
}
