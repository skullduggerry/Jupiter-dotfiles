pragma ComponentBehavior: Bound

import "../icons"
import "../panels"
import "../services"
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
    trailing: [
        TextButton {
            visible: root.count > 0
            text: "Clear"
            onClicked: history.wipe()
        },
        TextButton {
            text: QuickToggles.clipboardHistory ? "On" : "Off"
            color: QuickToggles.clipboardHistory ? Colors.accent.primary : Colors.text.muted
            onClicked: history.setEnabled(!QuickToggles.clipboardHistory)
        }
    ]

    delegate: Item {
        id: entry

        required property string modelData
        required property int index

        width: root.view.width
        height: Style.popup.itemHeight

        // Clicks only on the row itself: the list's box reaches over the
        // ring, and its mask keeps only the list's own presses off it.
        Rectangle {
            x: root.place(entry.y - root.view.contentY, entry.height)
            width: root.rowWidth
            height: entry.height
            radius: Style.popup.rowRadius
            color: entry.index === root.current ? Colors.base.hover : "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: root.pick(entry.index)
            }

            Text {
                text: history.label(entry.modelData)
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
                elide: Text.ElideRight
                maximumLineCount: 1

                anchors {
                    left: parent.left
                    right: forget.left
                    leftMargin: Style.widgets.padding
                    rightMargin: Style.widgets.spacing
                    verticalCenter: parent.verticalCenter
                }
            }

            TextButton {
                id: forget

                text: Icons.x
                font.family: Icons.font
                onClicked: history.forget(entry.modelData)

                anchors {
                    right: parent.right
                    rightMargin: Style.widgets.padding
                    verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    ClipboardHistory {
        id: history

        active: true
    }

    Text {
        id: empty

        visible: root.count === 0
        x: root.place(empty.y, empty.height)
        y: (root.view.height - empty.height) / 2
        width: root.rowWidth
        horizontalAlignment: Text.AlignHCenter
        text: QuickToggles.clipboardHistory ? "Nothing copied yet" : "History is off"
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.size
    }
}
