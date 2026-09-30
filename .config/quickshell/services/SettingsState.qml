pragma Singleton

import QtQuick
import Quickshell

// Whether the Settings app is open, and on which page, so that anything can
// open it: the quick settings' gear, the workspace dropdown's wallpaper.
Singleton {
    id: root

    property bool open: false
    // One of SettingsContent's page names, or one of a page's tabs.
    property string page: "appearance"

    // An empty page keeps the one last shown.
    function show(page: string) {
        if (page !== "")
            root.page = page;

        root.open = true;
    }

    // Closes it when it already shows that page, or any page for "".
    function toggle(page: string) {
        if (root.open && (page === "" || page === root.page))
            root.open = false;
        else
            root.show(page);
    }
}
