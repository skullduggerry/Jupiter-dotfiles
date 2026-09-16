pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string zoneAudio: "audio"
    readonly property string zoneBrightness: "brightness"
    readonly property int timeout: 1800
    property string zone: root.zoneAudio
    property real zoneAt: 0
    // Quick-settings surfaces on screen right now. They already show these same
    // panels, live and in the same corner, so an OSD over one of them is a
    // second copy of the same readout.
    property int viewers: 0
    property bool showing: false

    function show(zone: string) {
        root.zone = zone;
        root.zoneAt = Date.now();
        if (root.viewers > 0)
            return ;

        root.showing = true;
        linger.restart();
    }

    // "I was just using that one" — what a surface opening now should continue.
    function recentlyUsed() : bool {
        return Date.now() - root.zoneAt < root.timeout;
    }

    onViewersChanged: {
        if (root.viewers > 0)
            root.showing = false;

    }

    Timer {
        id: linger

        interval: root.timeout
        onTriggered: root.showing = false
    }

}
