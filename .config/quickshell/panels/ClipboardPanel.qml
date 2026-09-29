pragma ComponentBehavior: Bound

import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Io

// What cliphist holds, newest first: a click copies an entry again, × forgets
// it. The header switches the history on and off, as the Toggles page's
// Clipboard tile does, whose right click leads here.
PanelFrame {
    id: root

    // Read only while shown: the pager builds every page up front.
    required property bool active
    // cliphist's own lines, "<id>\t<preview>", which decode and delete take back.
    property var entries: []
    implicitHeight: root.chromeHeight + Math.max(Style.popup.itemHeight, entryList.contentHeight)

    function refresh() {
        if (lister.running)
            lister.stale = true;
        else
            lister.running = true;
    }

    // cliphist previews an image as "[[ binary data 13 KiB png 120x120 ]]".
    function label(line: string): string {
        const preview = line.slice(line.indexOf("\t") + 1);
        const image = preview.match(/^\[\[ binary data .+ (\w+) (\d+)x(\d+) \]\]$/);
        return image ? `${image[1].toUpperCase()} image, ${image[2]}×${image[3]}` : preview;
    }

    // The line goes to cliphist on stdin, never through a shell's quoting.
    function copy(line: string) {
        copier.line = line;
        copier.running = true;
    }

    function setHistory(enabled: bool) {
        QuickToggles.setClipboardHistory(enabled);
        root.refresh();
    }

    function forget(line: string) {
        forgetter.line = line;
        forgetter.running = true;
    }

    title: "Clipboard"
    onActiveChanged: {
        if (root.active)
            root.refresh();
    }
    trailing: [
        TextButton {
            visible: root.entries.length > 0
            text: "Clear"
            onClicked: wiper.running = true
        },
        TextButton {
            text: QuickToggles.clipboardHistory ? "On" : "Off"
            color: QuickToggles.clipboardHistory ? Colors.accent.primary : Colors.text.muted
            onClicked: root.setHistory(!QuickToggles.clipboardHistory)
        }
    ]

    // cliphist's database, watched (never read) while shown, so the list
    // follows copies made meanwhile; re-armed at every showing, which also
    // catches a database created since.
    FileView {
        path: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/cliphist/db"
        preload: false
        printErrors: false
        watchChanges: root.active
        onFileChanged: root.refresh()
    }

    Process {
        id: lister

        // A change that came in during a read: read once more afterwards.
        property bool stale: false

        command: ["cliphist", "list"]
        onRunningChanged: {
            if (!lister.running && lister.stale) {
                lister.stale = false;
                lister.running = true;
            }
        }

        stdout: StdioCollector {
            onStreamFinished: root.entries = text.split("\n").filter(line => line.includes("\t"))
        }
    }

    Process {
        id: copier

        property string line: ""

        command: ["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "sh", copier.line]
    }

    Process {
        id: forgetter

        property string line: ""

        command: ["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "sh", forgetter.line]
        onExited: root.refresh()
    }

    Process {
        id: wiper

        command: ["cliphist", "wipe"]
        onExited: root.refresh()
    }

    ListView {
        id: entryList

        anchors.fill: parent
        clip: true
        // Only vertically: the pager's two-finger swipe is horizontal wheel.
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        model: root.entries

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
                onClicked: root.copy(entry.modelData)
            }

            Text {
                text: root.label(entry.modelData)
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

                text: "\u{F0156}"
                onClicked: root.forget(entry.modelData)

                anchors {
                    right: parent.right
                    rightMargin: Style.widgets.padding
                    verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Text {
        anchors.centerIn: entryList
        visible: entryList.count === 0
        text: QuickToggles.clipboardHistory ? "Nothing copied yet" : "History is off"
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.size
    }
}
