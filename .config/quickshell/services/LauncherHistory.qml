pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    function count(key: string) : int {
        const stored = counts.launches[key];
        return stored === undefined ? 0 : stored;
    }

    function compare(left: DesktopEntry, right: DesktopEntry) : int {
        const difference = root.count(right.execString) - root.count(left.execString);
        if (difference !== 0)
            return difference;

        return left.name.localeCompare(right.name);
    }

    function record(key: string) {
        if (key === "")
            return ;

        const updated = Object.assign({
        }, counts.launches);
        updated[key] = root.count(key) + 1;
        counts.launches = updated;
        writeDebounce.restart();
    }

    Component.onCompleted: historyFile.text()

    Timer {
        id: writeDebounce

        interval: 200
        onTriggered: historyFile.writeAdapter()
    }

    FileView {
        id: historyFile

        path: Quickshell.statePath("launcher-history.json")
        preload: true
        blockLoading: true
        printErrors: false
        watchChanges: false

        adapter: JsonAdapter {
            id: counts

            property var launches: ({
            })
        }

    }

}
