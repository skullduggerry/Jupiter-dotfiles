pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// The default output's volume, as the volume keys and the bar's icon change it,
// and what PipeWire has to choose from, which the Sound page lists (binding the
// nodes, PwObjectTracker, while it shows them).
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: root.sink !== null && root.sink.ready && root.sink.audio !== null
    readonly property bool muted: root.ready && root.sink.audio.muted
    readonly property real volume: root.ready ? root.sink.audio.volume : 0
    readonly property real step: 0.05
    readonly property var nodes: Array.from(Pipewire.nodes.values).filter(node => node.audio !== null)
    // By PwNodeType's flags: a duplex device is an output and an input.
    readonly property var outputs: root.nodes.filter(node => !node.isStream && (node.type & PwNodeType.Sink) !== 0)
    readonly property var inputs: root.nodes.filter(node => !node.isStream && (node.type & PwNodeType.Source) !== 0)
    // Apps playing sound. A stream plays into a sink, so it carries the Sink
    // flag; a recording one carries Source instead.
    readonly property var apps: root.nodes.filter(node => node.type === PwNodeType.AudioOutStream)

    // HDMI outputs end their description in the monitor's name, which is
    // also their nickname and all that tells them apart.
    function label(node): string {
        if (node.nickname !== "" && node.description.endsWith("[" + node.nickname + "]"))
            return node.nickname;

        return node.description !== "" ? node.description : node.name;
    }

    function kind(node): string {
        const properties = node.properties || {};
        if (properties["device.api"] === "bluez5")
            return "Bluetooth";

        if (node.description.includes("HDMI") || node.description.includes("DisplayPort"))
            return "HDMI";

        if (node.description.includes("IEC958"))
            return "Digital (S/PDIF)";

        if (properties["device.bus"] === "usb")
            return "USB";

        if (properties["device.api"] === undefined)
            return "Virtual";

        return "Built-in";
    }

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
