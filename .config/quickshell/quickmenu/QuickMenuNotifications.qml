pragma ComponentBehavior: Bound

import "../icons"
import "../panels"
import "../services"
import "../style"
import QtQuick
import Quickshell.Services.Notifications

// The notifications out beside their slot, newest first, as the bar's centre
// lists them: using one runs what clicking it in its app's toast would (its
// default action), or opens the centre for one that has none; × and Delete
// dismiss it. Clear dismisses them all, and the bell is Do Not Disturb.
RingList {
    id: root

    function pick(index: int): bool {
        const notification = NotificationService.list[index];
        if (notification === undefined)
            return false;

        const action = Array.from(notification.actions).find(candidate => candidate.identifier === "default");
        if (action !== undefined)
            action.invoke();
        else
            NotificationService.toggleRequested();
        root.picked();
        return true;
    }

    function forget(index: int) {
        NotificationService.list[index]?.dismiss();
    }

    title: "Notifications"
    emptyText: NotificationService.doNotDisturb ? "Do not disturb" : "No notifications"
    model: NotificationService.list
    trailing: [
        TextButton {
            visible: NotificationService.count > 0
            text: "Clear"
            onClicked: NotificationService.dismissAll()
        },
        TextButton {
            text: NotificationService.doNotDisturb ? Icons.bellOff : Icons.bell
            font.family: Icons.font
            font.pixelSize: Style.text.iconSize
            color: Colors.icon.active
            onClicked: NotificationService.doNotDisturb = !NotificationService.doNotDisturb
        }
    ]

    delegate: RingRow {
        id: entry

        required property Notification modelData

        list: root

        Text {
            text: entry.modelData.summary !== "" ? entry.modelData.summary : entry.modelData.appName
            textFormat: Text.PlainText
            color: entry.tint(Colors.text.base)
            // Explicit, so that the left's mirroring keeps it at the hub.
            horizontalAlignment: Text.AlignLeft
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            elide: Text.ElideRight
            maximumLineCount: 1

            anchors {
                left: parent.left
                right: app.left
                leftMargin: Style.widgets.padding
                rightMargin: Style.widgets.spacing
                verticalCenter: parent.verticalCenter
            }
        }

        Text {
            id: app

            width: Math.min(implicitWidth, entry.width / 3)
            text: entry.modelData.appName
            textFormat: Text.PlainText
            color: entry.modelData.urgency === NotificationUrgency.Critical ? Colors.notification.urgent : entry.tint(Colors.text.muted)
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            elide: Text.ElideRight

            anchors {
                right: dismiss.left
                rightMargin: Style.widgets.spacing
                verticalCenter: parent.verticalCenter
            }
        }

        TextButton {
            id: dismiss

            text: Icons.x
            font.family: Icons.font
            onClicked: root.forget(entry.index)

            anchors {
                right: parent.right
                rightMargin: Style.widgets.padding
                verticalCenter: parent.verticalCenter
            }
        }
    }
}
