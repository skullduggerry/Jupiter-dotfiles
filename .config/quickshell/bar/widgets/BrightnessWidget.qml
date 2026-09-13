// bar/widgets/BrightnessWidget.qml
import QtQuick
import "../../services"
import "../../style"

Item {
    id: root

    readonly property var ramp: ["", "", "", "", "", "", "", "", ""]

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
