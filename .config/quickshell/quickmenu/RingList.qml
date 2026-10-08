pragma ComponentBehavior: Bound

import "../style"
import QtQuick

// A RingPanel of rows the menu picks (`current`) by the pointer or the
// arrows, as it picks an arc's items; a click, Enter or letting go uses one,
// and each list says what that does in pick(). One that is `searchable` (the
// apps') gets the menu's typing in `query` while `typing`.
RingPanel {
    id: root

    required property int current
    property bool searchable: false
    property bool typing: false
    property string query: ""
    property alias model: rows.model
    property alias delegate: rows.delegate
    readonly property int count: rows.count
    // Its rows, for a delegate's place on the curve as they scroll.
    readonly property ListView view: rows

    // A row was used: the menu goes.
    signal picked

    // The row at a point around the menu's centre, by its height alone: a
    // row reaches across the whole list, wherever the curve puts its content.
    function rowAt(x: real, y: real): int {
        const point = rows.mapFromItem(root.parent, x, y);
        return rows.indexAt(0, point.y + rows.contentY);
    }

    function show(index: int) {
        rows.positionViewAtIndex(index, ListView.Contain);
    }

    // Each list's own: false when there is no such row. Not every list
    // forgets (Delete).
    function pick(index: int): bool {
        return false;
    }

    function forget(index: int) {
    }

    contentHeight: Math.max(Style.popup.itemHeight, rows.contentHeight)

    ListView {
        id: rows

        anchors.fill: parent
        clip: true
        containmentMask: root.bodyMask
        boundsBehavior: Flickable.StopAtBounds
    }
}
