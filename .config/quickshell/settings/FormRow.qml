import "../style"
import QtQuick

// A row of a FormCard: its label in a column of its own, then the control,
// which may wrap onto more lines.
Item {
    id: root

    property string label: ""
    default property alias content: field.data

    width: parent ? parent.width : implicitWidth
    implicitHeight: Math.max(Style.popup.itemHeight, field.childrenRect.height)

    Text {
        width: Style.settings.rowLabelWidth - Style.bar.spacing
        height: Style.popup.itemHeight
        verticalAlignment: Text.AlignVCenter
        text: root.label
        color: Colors.text.base
        font.family: Style.text.font
        font.pixelSize: Style.text.size
        elide: Text.ElideRight
    }

    Item {
        id: field

        x: Style.settings.rowLabelWidth
        width: root.width - field.x
        height: root.height
    }
}
