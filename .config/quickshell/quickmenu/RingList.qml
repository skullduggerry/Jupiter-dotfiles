pragma ComponentBehavior: Bound

import "../services"
import "../style"
import QtQuick

// A list out beside the quick menu as a wheel around its centre, on `side`
// (1 right, -1 left): a fan from where a category's arc starts, its rows
// spokes along the radius (RingRow), the header (`leading`, the title,
// `trailing`) the first of them, its middle as near `level` (a height from
// the centre) as stays level enough to read. Each row reads out from the hub,
// so on the left its text keeps to the hub's end. The menu picks a row
// (`current`) by the pointer or the arrows, as it picks an arc's items, and
// the wheel turns the list under the pointer; a click, Enter or letting go
// uses one, and each list says what that does in pick(). One that is
// `searchable` (the apps') gets the menu's typing in `query` while `typing`.
Item {
    id: root

    required property int side
    property real level: 0
    property string title: ""
    property alias leading: leadingRow.data
    property alias trailing: trailingRow.data
    required property int current
    property bool searchable: false
    property bool typing: false
    property string query: ""
    // Shown on the first row while there are none.
    property string emptyText: ""
    property alias model: rows.model
    property alias delegate: rows.delegate
    readonly property int count: rows.count
    readonly property ListView view: rows
    readonly property real rowWidth: Style.quickMenu.fanWidth - Style.bar.padding * 2
    readonly property real pitch: Style.popup.itemHeight
    // A row's turn of the wheel, and how many fit.
    readonly property real step: Style.quickMenu.fanStep * Math.PI / 180
    readonly property int shownRows: Math.floor(2 * Style.quickMenu.fanSpan / Style.quickMenu.fanStep)
    // The rows laid out straight, the header first, as the ListView holds
    // them: `along` is a place on that line, which the wheel bends round.
    readonly property real length: root.pitch * (1 + Math.max(1, Math.min(root.shownRows, root.count)))
    // The rows' middle, which the fan's middle goes through; the header
    // sticks out past it.
    readonly property real centre: root.pitch + (root.length - root.pitch) / 2
    readonly property real ends: Style.bar.padding / Style.quickMenu.arcInner
    // How far round the middle is, below level on either side: toward the
    // slot, as far as keeps a full fan in the menu's own height, so that it
    // stays put as a search shortens the list.
    readonly property real middle: {
        const half = (1 + root.shownRows / 2) * root.step + root.ends;
        const most = Math.max(0, Math.asin(Math.min(1, Style.quickMenu.arcOuter / (Style.quickMenu.arcInner + Style.quickMenu.fanWidth))) - half);
        return Math.max(-most, Math.min(most, Math.asin(Math.max(-1, Math.min(1, root.level / Style.quickMenu.arcInner)))));
    }
    // Where the list has turned to, in whole rows: what it scrolls to.
    property real offset: 0
    property real reveal

    // A row was used: the menu goes.
    signal picked

    // How far round a place on the line is, below level.
    function angleAt(along: real): real {
        return root.middle + (along - root.centre) / root.pitch * root.step;
    }

    // How far out of the middle a place is, 0 to 1 at the fan's widest.
    function distance(along: real): real {
        return Math.min(1, Math.abs(along - root.centre) / (root.shownRows * root.pitch / 2));
    }

    // Takes an item of `width` by `height`, its top-left at (x, y) around
    // the centre, to the spoke at `along`, its end toward the hub at the
    // fan's inner edge, scaled by `scale` about that end.
    function spoke(along: real, x: real, y: real, width: real, height: real, scale: real): matrix4x4 {
        const turn = root.side * root.angleAt(along);
        const inner = Style.quickMenu.arcInner + Style.bar.padding;
        const hub = root.side > 0 ? 0 : width;
        const px = (root.side > 0 ? inner : -inner - width) + hub * (1 - scale);
        const py = -height / 2 + height / 2 * (1 - scale);
        const cos = Math.cos(turn);
        const sin = Math.sin(turn);
        return Qt.matrix4x4(scale * cos, -scale * sin, 0, cos * px - sin * py - x, scale * sin, scale * cos, 0, sin * px + cos * py - y, 0, 0, 1, 0, 0, 0, 0, 1);
    }

    // Where a point around the menu's centre is on the line, or NaN off the
    // fan.
    function alongAt(x: real, y: real): real {
        const radius = Math.hypot(x, y);
        const angle = Math.atan2(y, x * root.side);
        const along = (angle - root.middle) / root.step * root.pitch + root.centre;
        const within = radius >= Style.quickMenu.arcInner && radius <= Style.quickMenu.arcInner + Style.quickMenu.fanWidth;
        return within && angle >= root.angleAt(0) - root.ends && angle <= root.angleAt(root.length) + root.ends ? along : NaN;
    }

    function covers(x: real, y: real): bool {
        return !isNaN(root.alongAt(x, y));
    }

    // The row at a point around the menu's centre, -1 on the header or off
    // the rows.
    function rowAt(x: real, y: real): int {
        const along = root.alongAt(x, y);
        if (isNaN(along) || along < root.pitch)
            return -1;

        const row = Math.floor((along - root.pitch + root.offset) / root.pitch);
        return row < root.count ? row : -1;
    }

    function scrollTo(offset: real) {
        root.offset = Math.max(0, Math.min(rows.contentHeight - rows.height, offset));
        turning.to = root.offset;
        turning.restart();
    }

    // A row in view, as near the middle as the ends allow.
    function show(index: int) {
        root.scrollTo((index - Math.floor(root.shownRows / 2)) * root.pitch);
    }

    // The wheel turned by `by` rows.
    function turn(by: int) {
        root.scrollTo(root.offset + by * root.pitch);
    }

    // Each list's own: false when there is no such row. Not every list
    // forgets (Delete).
    function pick(index: int): bool {
        return false;
    }

    function forget(index: int) {
    }

    opacity: root.reveal
    scale: Style.quickMenu.calmFrom + (1 - Style.quickMenu.calmFrom) * root.reveal
    // Fewer rows (a search, a forgotten entry) may leave it past the end.
    onCountChanged: root.scrollTo(root.offset)

    NumberAnimation on reveal {
        from: 0
        to: 1
        duration: QuickMenu.playful ? Style.quickMenu.spring : Style.animation.normal
        easing.type: QuickMenu.playful ? Easing.OutBack : Easing.OutCubic
        easing.overshoot: Style.quickMenu.overshoot
    }

    NumberAnimation {
        id: turning

        target: rows
        property: "contentY"
        duration: Style.animation.fast
        easing.type: Easing.OutCubic
    }

    RingSector {
        readonly property real start: root.angleAt(0) - root.ends
        readonly property real end: root.angleAt(root.length) + root.ends

        inner: Style.quickMenu.arcInner
        outer: Style.quickMenu.arcInner + Style.quickMenu.fanWidth
        // Degrees clockwise from the top.
        from: root.side > 0 ? 90 + start * 180 / Math.PI : 270 - end * 180 / Math.PI
        to: root.side > 0 ? 90 + end * 180 / Math.PI : 270 - start * 180 / Math.PI
        corner: Style.bar.radius
        fillColor: Colors.base.surface
        strokeColor: Colors.base.border
    }

    Item {
        id: header

        width: root.rowWidth
        height: root.pitch
        LayoutMirroring.enabled: root.side < 0
        LayoutMirroring.childrenInherit: true
        transform: Matrix4x4 {
            matrix: root.spoke(root.pitch / 2, 0, 0, header.width, header.height, 1)
        }

        // At the hub's end, but in its own order on either side: what is
        // typed ends at the caret.
        Row {
            id: leadingRow

            LayoutMirroring.enabled: false
            LayoutMirroring.childrenInherit: true
            anchors.left: root.side > 0 ? parent.left : undefined
            anchors.right: root.side < 0 ? parent.right : undefined
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.widgets.spacing
        }

        Text {
            anchors.left: leadingRow.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }

        Row {
            id: trailingRow

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.bar.spacing
        }
    }

    // The rows' straight line, which each RingRow bends onto its spoke:
    // the menu takes the pointer and the wheel, so the list takes neither.
    ListView {
        id: rows

        y: root.pitch
        width: root.rowWidth
        height: root.length - root.pitch
        interactive: false
        boundsBehavior: Flickable.StopAtBounds
    }

    Text {
        id: empty

        visible: root.count === 0
        width: root.rowWidth
        height: root.pitch
        // Explicit, so that mirroring takes it to the hub's end on the left.
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        leftPadding: Style.widgets.padding
        rightPadding: Style.widgets.padding
        text: root.emptyText
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
        elide: Text.ElideRight
        LayoutMirroring.enabled: root.side < 0
        transform: Matrix4x4 {
            matrix: root.spoke(root.pitch * 1.5, 0, 0, empty.width, empty.height, 1)
        }
    }
}
