import "../icons"
import QtQuick
import Quickshell.Services.Pipewire

// A PipeWire node's volume: the icon mutes, moving the slider unmutes. The
// node has to be bound (PwObjectTracker) by whoever shows it.
SliderRow {
    id: root

    required property PwNode node
    property string volumeIcon: Icons.volume2
    property string mutedIcon: Icons.volumeX
    readonly property bool ready: root.node !== null && root.node.ready && root.node.audio !== null

    icon: root.ready && root.node.audio.muted ? root.mutedIcon : root.volumeIcon
    value: root.ready ? root.node.audio.volume : 0
    onIconClicked: {
        if (root.ready)
            root.node.audio.muted = !root.node.audio.muted;
    }
    onMoved: position => {
        if (!root.ready)
            return;

        root.node.audio.muted = false;
        root.node.audio.volume = position;
    }
}
