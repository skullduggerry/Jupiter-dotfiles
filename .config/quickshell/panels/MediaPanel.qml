pragma ComponentBehavior: Bound

import "../icons"
import "../services"
import "../style"
import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Widgets

// The player the bar shows (Media.active), an app or a browser tab: its cover,
// the track, where it is in it, and the controls. With several players, the
// pills at the bottom pick which one this is.
PanelFrame {
    id: root

    readonly property MprisPlayer player: Media.active
    // Live streams have no length to show a position in.
    readonly property bool timed: (root.player?.lengthSupported ?? false) && root.player.length > 0
    // Where a drag along the track has got to, until the player seeks there.
    property real seekTarget: -1
    readonly property real shownPosition: root.player === null ? 0 : root.seekTarget >= 0 ? root.seekTarget * root.player.length : root.player.position
    implicitHeight: root.chromeHeight + body.implicitHeight

    // m:ss, and h:mm:ss from an hour on.
    function clock(seconds: real): string {
        const whole = Math.max(0, Math.floor(seconds));
        const hours = Math.floor(whole / 3600);
        const minutes = Math.floor(whole / 60) % 60;
        const rest = String(whole % 60).padStart(2, "0");
        return hours > 0 ? `${hours}:${String(minutes).padStart(2, "0")}:${rest}` : `${minutes}:${rest}`;
    }

    title: "Media"
    trailing: Text {
        text: root.player?.identity ?? ""
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
    }

    // A player's position only updates when asked for while it plays.
    Timer {
        running: root.player?.isPlaying ?? false
        interval: Style.media.positionInterval
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    Timer {
        id: seek

        interval: Style.media.seekDelay
        onTriggered: {
            if (root.player?.canSeek)
                root.player.position = root.seekTarget * root.player.length;
            root.seekTarget = -1;
        }
    }

    Column {
        id: body

        width: parent.width
        spacing: Style.bar.spacing

        Row {
            width: parent.width
            spacing: Style.bar.padding

            ClippingRectangle {
                width: Style.media.artSize
                height: Style.media.artSize
                radius: Style.media.artRadius
                color: Colors.base.hover

                Icon {
                    anchors.centerIn: parent
                    visible: cover.status !== Image.Ready
                    text: Icons.music
                }

                Image {
                    id: cover

                    anchors.fill: parent
                    source: root.player !== null ? root.player.trackArtUrl : ""
                    sourceSize.width: Style.media.artSize
                    sourceSize.height: Style.media.artSize
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Style.media.artSize - parent.spacing

                Text {
                    width: parent.width
                    text: root.player?.trackTitle ?? ""
                    color: Colors.text.base
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size
                    font.weight: Font.Medium
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: root.player?.trackArtist ?? ""
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: root.player?.trackAlbum ?? ""
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                    elide: Text.ElideRight
                }
            }
        }

        Column {
            visible: root.timed
            width: parent.width

            PanelSlider {
                width: parent.width
                enabled: root.player?.canSeek ?? false
                value: root.timed ? root.shownPosition / root.player.length : 0
                onMoved: position => {
                    root.seekTarget = position;
                    seek.restart();
                }
            }

            Item {
                width: parent.width
                height: elapsed.implicitHeight

                Text {
                    id: elapsed

                    anchors.left: parent.left
                    text: root.clock(root.shownPosition)
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                }

                Text {
                    anchors.right: parent.right
                    text: root.clock(root.player?.length ?? 0)
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                }
            }
        }

        MediaControls {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.bar.padding * 2
        }

        PillGroup {
            visible: Media.players.length > 1
            width: parent.width
            compact: true
            choices: Media.players.map(player => ({
                        label: player.identity,
                        value: player.dbusName
                    }))
            current: root.player?.dbusName ?? ""
            onPicked: dbusName => Media.pick(dbusName)
        }
    }
}
