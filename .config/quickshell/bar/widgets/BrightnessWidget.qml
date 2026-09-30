import "../../icons"
import "../../services"
import "../../style"
import QtQuick

Item {
    id: root

    required property QuickPager pager
    readonly property list<string> ramp: [Icons.sunDim, Icons.sunMedium, Icons.sun]

    visible: Brightness.available
    implicitWidth: visible ? icon.implicitWidth + Style.widgets.padding * 2 : 0
    implicitHeight: Style.bar.height

    Binding {
        target: Brightness
        property: "active"
        value: true
    }

    Icon {
        id: icon

        anchors.centerIn: parent
        text: root.ramp[Math.round(Brightness.fraction * (root.ramp.length - 1))]
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.pager.toggleAt(root.pager.pageBrightness, root)
        onWheel: wheel => Brightness.adjust(wheel.angleDelta.y > 0 ? Brightness.step : -Brightness.step)
    }
}
