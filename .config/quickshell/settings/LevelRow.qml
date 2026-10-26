import "../panels"
import "../style"
import QtQuick

// A FormRow with a slider and, at its right, what it is set to: the Tablet
// page's pressure, the Mouse & Touchpad tab's speeds and scrolling.
FormRow {
    id: root

    property real position: 0
    property string reading: ""

    signal moved(real position)

    Row {
        width: parent.width
        height: Style.popup.itemHeight
        spacing: Style.widgets.spacing

        PanelSlider {
            width: parent.width - Style.settings.labelWidth - Style.widgets.spacing
            anchors.verticalCenter: parent.verticalCenter
            value: root.position
            onMoved: position => root.moved(position)
        }

        Text {
            width: Style.settings.labelWidth
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: root.reading
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
        }
    }
}
