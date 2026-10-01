pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris

// What is playing, from every MPRIS player: apps such as Spotify or YouTube
// Music, and the browser, which lists the tab playing (YouTube, YouTube Music,
// Spotify) as a player of its own. The bar and the media keys follow the one
// that started playing last, or the one picked in the bar's dropdown.
Singleton {
    id: root

    // A browser keeps an idle player with no track; playerctld only mirrors
    // another player.
    readonly property list<MprisPlayer> players: Mpris.players.values.filter(player => player.trackTitle !== "" && !player.dbusName.endsWith(".playerctld"))
    property string recent: ""
    readonly property MprisPlayer active: root.players.find(player => player.dbusName === root.recent) ?? root.players.find(player => player.isPlaying) ?? root.players[0] ?? null

    function pick(dbusName: string) {
        root.recent = dbusName;
    }

    function togglePlaying() {
        if (root.active?.canTogglePlaying)
            root.active.togglePlaying();
    }

    function next() {
        if (root.active?.canGoNext)
            root.active.next();
    }

    function previous() {
        if (root.active?.canGoPrevious)
            root.active.previous();
    }

    GlobalShortcut {
        name: "mediaPlayPause"
        onPressed: root.togglePlaying()
    }

    GlobalShortcut {
        name: "mediaNext"
        onPressed: root.next()
    }

    GlobalShortcut {
        name: "mediaPrevious"
        onPressed: root.previous()
    }

    Variants {
        model: Mpris.players.values

        Connections {
            id: watcher

            required property MprisPlayer modelData

            function onIsPlayingChanged() {
                if (watcher.modelData.isPlaying)
                    root.recent = watcher.modelData.dbusName;
            }

            target: watcher.modelData
            // One already playing when it turns up has started too.
            Component.onCompleted: watcher.onIsPlayingChanged()
        }
    }
}
