import "../../panels"
import "../../style"
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Item {
    id: root

    required property ShellScreen screen
    required property QuickPager pager
    readonly property UPowerDevice device: UPower.displayDevice
    readonly property int percent: Math.round(device.percentage * 100)
    readonly property bool charging: device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge
    readonly property bool full: device.state === UPowerDeviceState.FullyCharged
    readonly property color levelColor: {
        if (charging || full)
            return Colors.icon.active;

        if (percent <= 15)
            return Colors.icon.active;

        return Colors.icon.inactive;
    }

    visible: device.isLaptopBattery
    implicitWidth: visible ? Style.battery.width + Style.widgets.padding * 2 : 0
    implicitHeight: Style.bar.height

    Rectangle {
        id: pill

        anchors.centerIn: parent
        width: Style.battery.width
        height: Style.battery.height
        radius: Style.battery.radius
        color: "transparent"
        border.width: Style.border.width
        border.color: Colors.base.border

        Rectangle {
            width: Math.max(height, (parent.width - Style.battery.inset * 2) * root.device.percentage)
            radius: Style.battery.radius - Style.battery.inset
            color: root.levelColor
            opacity: Colors.base.opacity

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                margins: Style.battery.inset
            }

            Behavior on width {
                NumberAnimation {
                    duration: Style.animation.normal
                }

            }

        }

        Text {
            anchors.centerIn: parent
            text: root.charging ? "\uf0e7 " + root.percent : root.percent
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
        }

    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.pager.toggleAt(root.pager.pageBattery, root)
    }

}
