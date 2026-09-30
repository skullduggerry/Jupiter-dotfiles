import "../style"
import QtQuick

// A battery in the icons' line weight rather than a glyph per step: an outline,
// its terminal, and a bar inside as full as the charge.
Item {
    id: root

    property real level: 0
    property color color: Colors.icon.active

    implicitWidth: Style.battery.iconWidth + Style.battery.terminalWidth
    implicitHeight: Style.battery.iconHeight

    Rectangle {
        id: body

        width: Style.battery.iconWidth
        height: root.height
        radius: Style.battery.iconRadius
        color: "transparent"
        border.width: Style.border.width
        border.color: root.color

        Rectangle {
            readonly property int inset: Style.border.width + Style.battery.fillGap

            x: inset
            y: inset
            width: (body.width - inset * 2) * Math.max(0, Math.min(1, root.level))
            height: body.height - inset * 2
            radius: Math.max(0, body.radius - inset)
            color: root.color
        }
    }

    Rectangle {
        x: body.width
        anchors.verticalCenter: body.verticalCenter
        width: Style.battery.terminalWidth
        height: Style.battery.terminalHeight
        radius: Style.border.width
        color: root.color
    }
}
