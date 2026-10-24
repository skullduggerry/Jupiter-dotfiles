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
    model: history.entries
    trailing: ClipboardControls {
        clipboard: history
    }

    delegate: Rectangle {
        id: entry

        required property string modelData
        required property int index

        width: root.view.width
        height: Style.popup.itemHeight
        radius: Style.popup.rowRadius
        color: entry.index === root.current ? Colors.base.hover : "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: root.pick(entry.index)
        }

        ClipboardEntry {
            anchors.fill: parent
            clipboard: history
            line: entry.modelData
        }
    }

    ClipboardHistory {
        id: history

        active: true
    }

    Text {
        id: empty

        visible: root.count === 0
        y: (root.view.height - empty.height) / 2
        width: root.rowWidth
        horizontalAlignment: Text.AlignHCenter
        text: history.emptyText
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.size
    }
}
