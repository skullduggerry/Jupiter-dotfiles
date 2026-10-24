pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool doNotDisturb: false
    property var popupIds: []
    // Notification centres on screen (NotificationPanel counts itself). A
    // centre lists everything in the toasts' column, so toasts give way to it:
    // those showing expire as it opens, and none is raised while it is open.
    property int viewers: 0
    readonly property var tracked: server.trackedNotifications.values
    readonly property var list: root.tracked.filter(candidate => !candidate.transient).reverse()
    readonly property var popups: root.tracked.filter(candidate => root.popupIds.includes(candidate.id)).reverse()
    readonly property int count: root.list.length
    readonly property bool hasCritical: root.list.some(candidate => candidate.urgency === NotificationUrgency.Critical)

    // SUPER+N, for the bar's bell (NotificationWidget) to open its centre.
    signal toggleRequested

    // A body's markup without its images: an <img> would be fetched from
    // wherever it points. Again until none is left, since taking one out can
    // join the text around it into another ("<im<img>g src=…>").
    function withoutImages(body: string): string {
        let text = body;
        let previous = "";
        while (text !== previous) {
            previous = text;
            text = text.replace(/<img\b[^>]*>?/gi, "");
        }
        return text;
    }

    function hidePopup(id: int) {
        root.popupIds = root.popupIds.filter(candidate => candidate !== id);
    }

    function expirePopup(notification: Notification) {
        root.hidePopup(notification.id);
        if (notification.transient)
            notification.expire();
    }

    function dismissAll() {
        for (const notification of root.tracked.slice())
            notification.dismiss();
        root.popupIds = [];
    }

    function expirePopups() {
        for (const notification of root.popups.slice())
            root.expirePopup(notification);
    }

    onViewersChanged: {
        if (root.viewers > 0)
            root.expirePopups();
    }

    GlobalShortcut {
        name: "notificationsToggle"
        onPressed: root.toggleRequested()
    }

    NotificationServer {
        id: server

        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        inlineReplySupported: true
        persistenceSupported: true
        onNotification: notification => {
            notification.tracked = true;
            if (notification.lastGeneration)
                return;

            if (root.viewers > 0) {
                // The open centre lists it, but not a transient one, which
                // would otherwise stay tracked with nowhere to show.
                if (notification.transient)
                    notification.expire();

                return;
            }
            if (root.doNotDisturb && notification.urgency !== NotificationUrgency.Critical)
                return;

            root.popupIds = root.popupIds.concat([notification.id]);
        }
    }
}
