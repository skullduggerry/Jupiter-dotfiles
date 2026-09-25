import "../style"
import QtQuick

// The design's pill: a tab, one half of a two-way choice, or (action) a
// plain button, which reads at full strength without looking chosen.
// Compact is the same pill in a panel's small type, to sit in a panel row.
Rectangle {
    id: root

    property string text: ""
    property bool checked: false
    property bool action: false
    property bool compact: false
    readonly property int padding: root.compact ? Style.widgets.padding : Style.wallpaper.padding

    signal clicked()

    implicitWidth: label.implicitWidth + root.padding * 2
    implicitHeight: Style.popup.itemHeight
    radius: root.height / 2
    color: {
        if (root.checked)
            return Colors.pill.selected;

        if (area.containsMouse || root.action)
            return Colors.base.hover;

        return Colors.pill.idle;
    }

    Text {
        id: label

        anchors.centerIn: parent
        // A pill given a width of its own, like a segment, elides instead of spilling.
        width: Math.min(implicitWidth, root.width - root.padding * 2)
        text: root.text
        color: root.checked || root.action ? Colors.text.base : Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: root.compact ? Style.text.smallSize : Style.text.size
        font.weight: root.checked ? Font.Medium : Font.Normal
        elide: Text.ElideRight
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Behavior on color {
        ColorAnimation {
            duration: Style.animation.normal
        }

    }

}
