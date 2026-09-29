pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// The default output's volume, as the volume keys and the bar's icon change it.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: root.sink !== null && root.sink.ready && root.sink.audio !== null
    readonly property bool muted: root.ready && root.sink.audio.muted
    readonly property real volume: root.ready ? root.sink.audio.volume : 0
    readonly property real step: 0.05

    // Unmutes, as a volume key does.
    function adjust(delta: real) {
        if (!root.ready)
            return;

        root.sink.audio.muted = false;
        root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + delta));
    }

    function toggleMute() {
        if (root.ready)
            root.sink.audio.muted = !root.sink.audio.muted;
    }

    PwObjectTracker {
        objects: root.sink !== null ? [root.sink] : []
    }
}
