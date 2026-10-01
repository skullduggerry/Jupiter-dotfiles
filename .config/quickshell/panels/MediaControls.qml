import "../icons"
import "../services"
import "../style"
import QtQuick
import Quickshell.Services.Mpris

// Back, play or pause, and skip, for the player the bar shows. What the player
// does not offer (a single video has nothing to skip to) is dimmed.
Row {
    id: root

    readonly property MprisPlayer player: Media.active

    TextButton {
        anchors.verticalCenter: parent.verticalCenter
        enabled: root.player?.canGoPrevious ?? false
        text: Icons.skipBack
        font.family: Icons.font
        font.pixelSize: Style.text.iconSize
        color: enabled ? Colors.icon.active : Colors.icon.disabled
        onClicked: Media.previous()
    }

    TextButton {
        anchors.verticalCenter: parent.verticalCenter
        enabled: root.player?.canTogglePlaying ?? false
        text: root.player?.isPlaying ? Icons.pause : Icons.play
        font.family: Icons.font
        font.pixelSize: Style.text.iconSize
        color: enabled ? Colors.icon.active : Colors.icon.disabled
        onClicked: Media.togglePlaying()
    }

    TextButton {
        anchors.verticalCenter: parent.verticalCenter
        enabled: root.player?.canGoNext ?? false
        text: Icons.skipForward
        font.family: Icons.font
        font.pixelSize: Style.text.iconSize
        color: enabled ? Colors.icon.active : Colors.icon.disabled
        onClicked: Media.next()
    }
}
