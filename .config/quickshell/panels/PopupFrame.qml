import "../style"
import QtQuick

// The glass a dropdown is drawn on, with the bar's corners and border, and how
// it comes and goes. With Theme.swoosh it springs out of the bar from
// `originX` on its top edge, past its height and back, its content a beat
// behind, and goes back in when closed; otherwise it is simply there while
// `open`, and Hyprland fades the window. Its window stays up while `shown`.
Rectangle {
    id: root

    property bool open: false
    // Where on its top edge it comes out of the bar, and goes back in.
    property real originX: root.width / 2
    // 0 in the bar, 1 in place, past 1 as it overshoots.
    property real reveal: root.open ? 1 : 0
    readonly property bool shown: root.open || root.reveal > 0
    default property alias content: body.data

    radius: Style.bar.radius
    color: Colors.base.surface
    border.color: Colors.base.border
    border.width: Style.border.width
    clip: true
    opacity: Math.min(1, root.reveal / Style.swoosh.fade)
    transform: [
        Scale {
            origin.x: Math.max(Style.bar.radius, Math.min(root.width - Style.bar.radius, root.originX))
            xScale: Style.swoosh.fromWidth + (1 - Style.swoosh.fromWidth) * Math.min(1, root.reveal)
            yScale: Style.swoosh.fromHeight + (1 - Style.swoosh.fromHeight) * root.reveal
        },
        // From the bar's edge, across the gap under it.
        Translate {
            y: -Style.popup.topMargin * (1 - root.reveal)
        }
    ]

    // Clicks on the panel stay on it rather than dismissing it.
    MouseArea {
        anchors.fill: parent
    }

    Item {
        id: body

        anchors.fill: parent
        opacity: Math.max(0, Math.min(1, (root.reveal - Style.swoosh.contentFrom) / (1 - Style.swoosh.contentFrom)))
    }

    // Out with a spring, back in accelerating: the target says which way.
    Behavior on reveal {
        id: motion

        enabled: Theme.swoosh

        NumberAnimation {
            duration: motion.targetValue > 0 ? Style.swoosh.enter : Style.swoosh.leave
            easing.type: motion.targetValue > 0 ? Easing.OutBack : Easing.InQuad
            easing.overshoot: Style.swoosh.overshoot
        }
    }
}
