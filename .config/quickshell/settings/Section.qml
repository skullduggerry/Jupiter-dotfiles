import "../style"
import QtQuick

// A group of controls under the design's upper-case heading.
Column {
    id: root

    property string title: ""
    default property alias content: body.data

    spacing: Style.bar.spacing

    Text {
        text: root.title
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
        font.weight: Font.Medium
    }

    Column {
        id: body

        spacing: Style.bar.spacing
    }
}
