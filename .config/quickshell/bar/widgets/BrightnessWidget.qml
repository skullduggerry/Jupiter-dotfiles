import "../../services"
import "../../style"
import QtQuick

Item {
    id: root

    required property QuickPager pager
    readonly property var ramp: ["", "", "", "", "", "", "", "", ""]

    visible: Brightness.available
    implicitWidth: visible ? Style.text.iconSize + Style.widgets.spacing : 0
    implicitHeight: Style.bar.height

    Binding {
        target: Brightness
        property: "active"
        value: true
    }

    Text {
        anchors.centerIn: parent
        text: root.ramp[Math.round(Brightness.fraction * (root.ramp.length - 1))]
        color: Colors.icon.active
        font.family: Style.text.font
        font.pixelSize: Style.text.iconSize
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.pager.toggleAt(root.pager.pageBrightness, root)
        onWheel: (wheel) => {
            return Brightness.adjust(wheel.angleDelta.y > 0 ? Brightness.step : -Brightness.step);
        }
    }

}
