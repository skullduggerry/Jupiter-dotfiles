import "../icons"
import "../style"
import QtQuick
import Quickshell

// A panel header's way out to the full app for its settings (blueman,
// nm-connection-editor, pavucontrol), for whatever the panel does not cover.
TextButton {
    id: root

    required property list<string> command

    text: Icons.externalLink
    font.family: Icons.font
    font.pixelSize: Style.text.iconSize
    color: Colors.icon.active
    onClicked: Quickshell.execDetached(root.command)
}
