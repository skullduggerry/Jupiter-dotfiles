pragma ComponentBehavior: Bound

import "../services"
import "../style"
import QtQuick
import Quickshell.Services.Mpris

// The player the bar shows (Media.active), an app or a browser tab: its cover,
// the track, where it is in it, and the controls. With several players, the
// pills at the bottom pick which one this is.
PanelFrame {
    id: root

    readonly property MprisPlayer player: Media.active
    implicitHeight: root.chromeHeight + body.implicitHeight

    title: "Media"
    trailing: Text {
        text: root.player?.identity ?? ""
        textFormat: Text.PlainText
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
    }

    Column {
        id: body

        width: parent.width
        spacing: Style.bar.spacing

        Row {
            width: parent.width
            spacing: Style.bar.padding

            CoverArt {
                width: Style.media.artSize
                height: Style.media.artSize
                source: root.player?.trackArtUrl ?? ""
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Style.media.artSize - parent.spacing

                Text {
                    width: parent.width
                    text: root.player?.trackTitle ?? ""
                    textFormat: Text.PlainText
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
                    textFormat: Text.PlainText
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: root.player?.trackAlbum ?? ""
                    textFormat: Text.PlainText
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                    elide: Text.ElideRight
                }
            }
        }

        TrackSeek {
            width: parent.width
            player: root.player
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
