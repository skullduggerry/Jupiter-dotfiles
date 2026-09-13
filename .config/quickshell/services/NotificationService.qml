// services/NotificationService.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool doNotDisturb: false
    property var popupIds: []

    readonly property var tracked: server.trackedNotifications.values

    readonly property var list: root.tracked.filter(candidate => !candidate.transient).reverse()

    readonly property var popups: root.tracked
        .filter(candidate => root.popupIds.indexOf(candidate.id) !== -1)
        .reverse()

    readonly property int count: root.list.length

    readonly property bool hasCritical: root.list.some(candidate => candidate.urgency === NotificationUrgency.Critical)

    function hidePopup(id: int) {
        root.popupIds = root.popupIds.filter(candidate => candidate !== id)
    }

    function expirePopup(notification: Notification) {
        root.hidePopup(notification.id)
        if (notification.transient) notification.expire()
    }

    function dismissAll() {
        const all = root.tracked.slice()
        for (let index = 0; index < all.length; index++) all[index].dismiss()
        root.popupIds = []
    }

    NotificationServer {
        id: server

        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: (notification) => {
            notification.tracked = true
            if (notification.lastGeneration) return
            if (root.doNotDisturb && notification.urgency !== NotificationUrgency.Critical) return
            root.popupIds = [...root.popupIds, notification.id]
        }
    }
}
