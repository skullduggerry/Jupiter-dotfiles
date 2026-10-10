pragma ComponentBehavior: Bound

import "../style"
import QtQuick

// What cliphist holds, newest first: a click copies an entry again, × forgets
// it. The header switches the history on and off, as the Toggles page's
// Clipboard tile does, whose right click leads here.
PanelFrame {
    id: root

    // Read only while shown: the pager builds every page up front.
    required property bool active
    implicitHeight: root.chromeHeight + Math.max(Style.popup.itemHeight, entryList.contentHeight)

    title: "Clipboard"
    trailing: ClipboardControls {
        clipboard: history
    }

    ClipboardHistory {
        id: history

        active: root.active
    }

    ListView {
        id: entryList

        anchors.fill: parent
        clip: true
        // Only vertically: the pager's two-finger swipe is horizontal wheel.
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        model: history.entries

        delegate: Rectangle {
            id: entry

            required property string modelData

            width: entryList.width
            height: Style.popup.itemHeight
            radius: Style.popup.rowRadius
            color: entryArea.containsMouse ? Colors.base.hover : "transparent"

            MouseArea {
                id: entryArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: history.copy(entry.modelData)
            }

            ClipboardEntry {
                anchors.fill: parent
                clipboard: history
                line: entry.modelData
            }
        }
    }

    Text {
        anchors.centerIn: entryList
        visible: entryList.count === 0
        text: history.emptyText
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.size
    }
}
