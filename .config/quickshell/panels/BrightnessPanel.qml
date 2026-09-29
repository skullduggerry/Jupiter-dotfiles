import "../services"
import "../style"
import QtQuick

PanelFrame {
    id: root

    implicitHeight: root.chromeHeight + rows.implicitHeight

    title: "Brightness"

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
            icon: "\u{F00DF}"
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
