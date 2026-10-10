import "../style"
import QtQuick
import Quickshell.Services.Mpris

// Where a player is in its track: a slider to seek along, the time gone and
// the length under it. Hidden for a live stream, which has no length.
Column {
    id: root

    required property MprisPlayer player
    readonly property bool timed: (root.player?.lengthSupported ?? false) && root.player.length > 0
    // Where a drag along the track has got to, until the player seeks there.
    property real seekTarget: -1
    readonly property real shownPosition: root.player === null ? 0 : root.seekTarget >= 0 ? root.seekTarget * root.player.length : root.player.position

    // m:ss, and h:mm:ss from an hour on.
    function clock(seconds: real): string {
        const whole = Math.max(0, Math.floor(seconds));
        const hours = Math.floor(whole / 3600);
        const minutes = Math.floor(whole / 60) % 60;
        const rest = String(whole % 60).padStart(2, "0");
        return hours > 0 ? `${hours}:${String(minutes).padStart(2, "0")}:${rest}` : `${minutes}:${rest}`;
    }

    visible: root.timed

    // A player's position only updates when asked for while it plays.
    Timer {
        running: root.visible && (root.player?.isPlaying ?? false)
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
