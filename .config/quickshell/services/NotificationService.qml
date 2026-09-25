pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool doNotDisturb: false
    property var popupIds: []

    // Notification centres on screen, counted by NotificationPanel. A centre
    // opens in the column toasts pop up in and already lists everything, so
    // toasts give way to it: those showing expire as it opens, and nothing
    // new raises one while it is open.
    property int viewers: 0

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

    function expirePopups() {
        const shown = root.popups.slice()
        for (let index = 0; index < shown.length; index++) root.expirePopup(shown[index])
    }

    onViewersChanged: if (root.viewers > 0) root.expirePopups()

    NotificationServer {
        id: server

        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: (notification) => {
            notification.tracked = true
            if (notification.lastGeneration) return
            if (root.viewers > 0) {
                // The open centre lists it. It does not list a transient one,
                // which would otherwise stay tracked with nowhere to show.
                if (notification.transient) notification.expire()
                return
            }
            if (root.doNotDisturb && notification.urgency !== NotificationUrgency.Critical) return
            root.popupIds = [...root.popupIds, notification.id]
        }
    }
}
