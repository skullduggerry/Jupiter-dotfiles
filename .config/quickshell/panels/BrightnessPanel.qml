import "../icons"
import "../services"
import "../style"
import QtQuick

PanelFrame {
    id: root

    // On screen: the pagers build every page up front.
    required property bool active
    property bool counted: false
    implicitHeight: root.chromeHeight + rows.implicitHeight

    // Counted while shown, so the level is read meanwhile. Kept idempotent,
    // as a pager's Loader destroys this while `active` is still true.
    function syncViewer() {
        if (root.active === root.counted)
            return;

        Brightness.viewers += root.active ? 1 : -1;
        root.counted = root.active;
    }

    title: "Brightness"
    onActiveChanged: root.syncViewer()
    Component.onCompleted: root.syncViewer()
    Component.onDestruction: {
        if (root.counted)
            Brightness.viewers -= 1;
    }

    Binding {
        target: Brightness
        property: "active"
        value: true
    }

    Column {
        id: rows

        width: parent.width

        SliderRow {
            visible: Brightness.available
            width: parent.width
            icon: Icons.sunMedium
            value: Brightness.fraction
            onMoved: position => Brightness.setPercent(Math.round(position * 100))
        }

        Text {
            visible: !Brightness.available
            text: "No backlight found"
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }
    }
}
