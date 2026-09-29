import "../style"
import QtQuick

// A word or a glyph to click: muted until the pointer is on it, and easier to
// hit than it is big.
Text {
    id: root

    readonly property bool hovered: area.containsMouse

    signal clicked

    color: root.hovered ? Colors.text.base : Colors.text.muted
    font.family: Style.text.font
    font.pixelSize: Style.text.smallSize

    MouseArea {
        id: area

        anchors.fill: parent
        anchors.margins: -Style.widgets.spacing
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
