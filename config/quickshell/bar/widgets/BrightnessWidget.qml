// bar/widgets/BrightnessWidget.qml
//
// Display backlight, as the one glyph the waybar config used for it: a circle
// that fills from empty to full, no percentage. The ramp below is that
// config's `backlight.format-icons` verbatim, so this reads exactly as it did
// there.
//
// Scrolling adjusts it, which is the same gesture the volume widget uses.
// Hidden entirely when the machine has no backlight to speak of.
import QtQuick
import "../../services"
import "../../style"

Item {
    id: root

    readonly property var ramp: ["", "", "", "", "", "", "", "", ""]

    // Holds the service on for this widget's lifetime; nothing else reads it.
    Binding {
        target: Brightness
        property: "active"
        value: true
    }

    visible: Brightness.available
    implicitWidth: visible ? Style.text.iconSize + Style.widgets.spacing : 0
    implicitHeight: Style.bar.height

    Text {
        anchors.centerIn: parent
        text: root.ramp[Math.round(Brightness.fraction * (root.ramp.length - 1))]
        color: Colors.usage.normal
        font.family: Style.text.font
        font.pixelSize: Style.text.iconSize
    }

    MouseArea {
        anchors.fill: parent
        onWheel: (wheel) => Brightness.adjust(wheel.angleDelta.y > 0 ? Brightness.step : -Brightness.step)
    }
}
