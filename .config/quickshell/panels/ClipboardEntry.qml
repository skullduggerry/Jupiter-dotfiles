import "../icons"
import "../style"
import QtQuick

// What one entry of the clipboard history holds, with × to forget it: the
// inside of a row of ClipboardPanel and of the quick menu's list.
Item {
    id: root

    required property ClipboardHistory clipboard
    required property string line

    Text {
        text: root.clipboard.label(root.line)
        textFormat: Text.PlainText
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
        onClicked: root.clipboard.forget(root.line)

        anchors {
            right: parent.right
            rightMargin: Style.widgets.padding
            verticalCenter: parent.verticalCenter
        }
    }
}
