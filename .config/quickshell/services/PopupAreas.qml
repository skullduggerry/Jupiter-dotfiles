pragma Singleton

import QtQuick
import Quickshell

// What the open popups cover, so the toasts can move below one lying across
// their column rather than over it (Toasts.qml). Popups and toasts both sit
// under the bar's exclusive zone, so their coordinates are the same.
Singleton {
    id: root

    // {owner, screen, x, y, width, height}, one per open popup.
    property var areas: []

    // A null area takes the owner's out, as closing or destruction does.
    function set(owner: QtObject, area) {
        const next = root.areas.filter(entry => entry.owner !== owner);
        if (area !== null)
            next.push(Object.assign({
                owner: owner
            }, area));

        root.areas = next;
    }

    // The lowest edge among the popups on that screen that overlap the span.
    function bottomOver(screen: string, left: real, right: real): real {
        let bottom = 0;
        for (const area of root.areas) {
            if (area.screen === screen && area.x < right && area.x + area.width > left)
                bottom = Math.max(bottom, area.y + area.height);
        }
        return bottom;
    }
}
