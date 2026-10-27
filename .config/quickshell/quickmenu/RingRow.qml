import "../style"
import QtQuick

// A row of a RingList, the delegate's root, bent onto its spoke: smaller and
// fainter the further it is from the fan's middle, as a picker wheel's rows
// are, and a pill while picked. Its content lays out as on the menu's right,
// and mirrored on its left, so that it reads out from the hub; its Texts take
// their colours through tint().
Item {
    id: root

    required property RingList list
    required property int index
    default property alias content: face.data
    readonly property bool picked: root.index === root.list.current
    // Its middle on the list's line, and how far that is out of the middle.
    readonly property real along: root.list.pitch + root.y - root.list.view.contentY + root.height / 2
    readonly property real away: root.list.distance(root.along)
    readonly property real fade: {
        if (root.picked)
            return 0;

        const t = Math.max(0, Math.min(1, (root.away - 0.15) / 0.85));
        return t * t * (3 - 2 * t);
    }

    function tint(full: color): color {
        return Colors.faded(full, root.fade);
    }

    width: root.list.rowWidth
    height: root.list.pitch
    // Going, half past either end of the fan.
    opacity: Math.max(0, Math.min(1, Math.min(root.along - root.list.pitch, root.list.length - root.along) / (root.list.pitch / 2)))
    transform: Matrix4x4 {
        matrix: root.list.spoke(root.along, 0, root.list.pitch + root.y - root.list.view.contentY, root.width, root.height, 1 - Style.quickMenu.fanShrink * root.away * root.away)
    }

    Rectangle {
        id: face

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: Style.quickMenu.fanRowHeight
        radius: Style.popup.rowRadius
        color: root.picked ? Colors.pill.selected : "transparent"
        LayoutMirroring.enabled: root.list.side < 0
        LayoutMirroring.childrenInherit: true
    }
}
