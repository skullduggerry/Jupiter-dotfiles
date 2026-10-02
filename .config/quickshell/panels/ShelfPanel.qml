pragma ComponentBehavior: Bound

import "../icons"
import "../services"
import "../style"
import QtQuick
import Quickshell.Io

// The shelf (services/Shelf), newest first: notes written here, the clipboard
// pasted, and what other devices put in the folder. A click copies an item, a
// right click opens it, × deletes it.
PanelFrame {
    id: root

    readonly property bool wantsKeyboard: true
    readonly property string statusText: Shelf.error !== "" ? Shelf.error : Shelf.synced ? "" : "Only on this machine: no Nextcloud folder found"
    readonly property list<string> imageSuffixes: ["png", "jpg", "jpeg", "gif", "webp", "bmp", "svg"]
    readonly property list<string> textSuffixes: ["txt", "md"]
    implicitHeight: root.chromeHeight + note.height + Style.bar.spacing + Math.max(Style.popup.itemHeight, itemList.contentHeight) + status.height

    // An item was copied or opened, so whoever shows this can close.
    signal picked

    function focusNote() {
        note.focusInput();
    }

    title: "Shelf"
    trailing: [
        TextButton {
            text: Icons.clipboardPaste
            font.family: Icons.font
            font.pixelSize: Style.text.iconSize
            color: Colors.icon.active
            onClicked: Shelf.paste(false)
        },
        TextButton {
            text: Icons.folderOpen
            font.family: Icons.font
            font.pixelSize: Style.text.iconSize
            color: Colors.icon.active
            onClicked: {
                Shelf.open(Shelf.directory);
                root.picked();
            }
        }
    ]

    InputField {
        id: note

        icon: Icons.fileText
        placeholder: "A note, Enter puts it on the shelf"
        onAccepted: {
            Shelf.addNote(note.text);
            note.text = "";
        }

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
    }

    Item {
        id: status

        height: statusLabel.visible ? statusLabel.implicitHeight + Style.bar.spacing : 0

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        Text {
            id: statusLabel

            anchors.bottom: parent.bottom
            width: parent.width
            visible: root.statusText !== ""
            text: root.statusText
            color: Shelf.error !== "" ? Colors.status.error : Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            wrapMode: Text.Wrap
        }
    }

    ListView {
        id: itemList

        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        model: Shelf.files

        anchors {
            top: note.bottom
            bottom: status.top
            left: parent.left
            right: parent.right
            topMargin: Style.bar.spacing
        }

        delegate: Rectangle {
            id: item

            required property string fileName
            required property string filePath
            required property url fileUrl
            required property string fileSuffix
            required property real fileSize
            readonly property bool image: root.imageSuffixes.includes(item.fileSuffix.toLowerCase())
            readonly property bool textual: root.textSuffixes.includes(item.fileSuffix.toLowerCase())
            readonly property string firstLine: preview.text().split("\n").find(line => line.trim() !== "") || ""

            width: itemList.width
            height: item.image ? Style.shelf.thumbnailHeight + Style.widgets.spacing * 2 : Style.popup.itemHeight
            radius: Style.popup.rowRadius
            color: itemArea.containsMouse ? Colors.base.hover : "transparent"

            FileView {
                id: preview

                path: item.textual && item.fileSize <= Style.shelf.previewBytes ? item.filePath : ""
                printErrors: false
            }

            MouseArea {
                id: itemArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton)
                        Shelf.open(item.filePath);
                    else
                        Shelf.copy(item.filePath);
                    root.picked();
                }
            }

            Image {
                id: thumbnail

                visible: item.image
                source: item.image ? item.fileUrl : ""
                height: Style.shelf.thumbnailHeight
                width: item.image ? Math.min(height * 2, height * implicitWidth / Math.max(1, implicitHeight)) : 0
                sourceSize.height: Style.shelf.thumbnailHeight * 2
                fillMode: Image.PreserveAspectFit
                asynchronous: true

                anchors {
                    left: parent.left
                    leftMargin: Style.widgets.padding
                    verticalCenter: parent.verticalCenter
                }
            }

            Icon {
                id: glyph

                visible: !item.image
                width: item.image ? 0 : Style.popup.rowIconWidth
                text: item.textual ? Icons.fileText : Icons.file
                font.pixelSize: Style.text.size

                anchors {
                    left: thumbnail.right
                    verticalCenter: parent.verticalCenter
                }
            }

            Text {
                text: item.firstLine !== "" ? item.firstLine : item.fileName
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
                elide: Text.ElideRight
                maximumLineCount: 1

                anchors {
                    left: glyph.right
                    right: remove.left
                    leftMargin: Style.widgets.spacing
                    rightMargin: Style.widgets.spacing
                    verticalCenter: parent.verticalCenter
                }
            }

            TextButton {
                id: remove

                text: Icons.x
                font.family: Icons.font
                onClicked: Shelf.remove(item.filePath)

                anchors {
                    right: parent.right
                    rightMargin: Style.widgets.padding
                    verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Text {
        anchors.centerIn: itemList
        visible: itemList.count === 0
        text: "Nothing on the shelf yet"
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.size
    }
}
