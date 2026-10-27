pragma ComponentBehavior: Bound

import "../panels"
import "../style"
import QtQuick

// The clipboard history out beside its slot, newest first: using an entry
// copies it, to be pasted; × and Delete forget it.
RingList {
    id: root

    function pick(index: int): bool {
        if (index < 0 || index >= history.entries.length)
            return false;

        history.copy(history.entries[index]);
        root.picked();
        return true;
    }

    function forget(index: int) {
        if (index >= 0 && index < history.entries.length)
            history.forget(history.entries[index]);
    }

    title: "Clipboard"
    emptyText: history.emptyText
    model: history.entries
    trailing: ClipboardControls {
        clipboard: history
    }

    delegate: RingRow {
        id: entry

        required property string modelData

        list: root

        ClipboardEntry {
            anchors.fill: parent
            clipboard: history
            line: entry.modelData
            color: entry.tint(Colors.text.base)
        }
    }

    ClipboardHistory {
        id: history

        active: true
    }
}
