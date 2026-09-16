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
    readonly property var ramp: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    readonly property var chargingRamp: ["󰢟", "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
    readonly property string icon: {
        const step = Math.round(Math.max(0, Math.min(1, root.device.percentage)) * (root.ramp.length - 1));
        return root.charging || root.full ? root.chargingRamp[step] : root.ramp[step];
    }
    // Colour only carries the states that want acting on, the way the usage
    // meters on the other side of the bar do.
    readonly property color levelColor: {
        // Charging is already in the glyph, so it needs no colour of its own;
        // colour is kept for the two states that want doing something about.
        if (root.charging || root.full)
            return Colors.battery.normal;

        if (root.percent <= 10)
            return Colors.battery.critical;

        if (root.percent <= 20)
            return Colors.battery.low;

        return Colors.battery.normal;
    }

    visible: device.isLaptopBattery
    implicitWidth: visible ? row.implicitWidth + Style.widgets.padding * 2 : 0
    implicitHeight: Style.bar.height

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Style.widgets.spacing

        Text {
            text: root.icon
            color: root.levelColor
            font.family: Style.text.font
            font.pixelSize: Style.text.iconSize
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.percent
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            anchors.verticalCenter: parent.verticalCenter
        }

    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.pager.toggleAt(root.pager.pageBattery, root)
    }

}
