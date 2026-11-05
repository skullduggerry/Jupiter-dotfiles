import "../panels"
import "../services"
import "../style"
import QtQuick
import Quickshell.Services.Notifications

Rectangle {
    id: root

    required property Notification modelData
    readonly property int notificationId: root.modelData.id
    readonly property bool urgent: root.modelData.urgency === NotificationUrgency.Critical
    required property int timeout
    // The only toast showing fills the toasts' window, which Hyprland's lens
    // then frames; in a stack, each draws its own rim.
    property bool alone: false

    implicitHeight: entry.implicitHeight + Style.bar.padding * 2
    radius: Style.bar.radius
    color: Colors.base.surface
    border.width: Style.border.width
    border.color: root.urgent ? Colors.notification.urgent : Colors.base.edge

    GlassHighlight {
        lensed: root.alone
    }

    Timer {
        running: root.timeout > 0 && !entry.replying
        interval: root.timeout
        onTriggered: NotificationService.expirePopup(root.modelData)
    }

    NotificationEntry {
        id: entry

        modelData: root.modelData
        onDismissed: NotificationService.hidePopup(root.notificationId)

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Style.bar.padding
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: NotificationService.hidePopup(root.notificationId)
    }
}
