import "../../icons"
import "../../style"
import QtQuick
import Quickshell.Services.UPower

Item {
    id: root

    required property QuickPager pager
    readonly property UPowerDevice device: UPower.displayDevice
    readonly property int percent: Math.round(device.percentage * 100)
    readonly property bool charging: device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge
    readonly property bool full: device.state === UPowerDeviceState.FullyCharged
    // Colour only for the states that want acting on, as the usage meters do;
    // on power is the bolt.
    readonly property color levelColor: {
        if (root.charging || root.full || root.percent > Style.battery.lowAt)
            return Colors.battery.normal;

        return root.percent > Style.battery.criticalAt ? Colors.battery.low : Colors.battery.critical;
    }

    visible: device.isLaptopBattery
    implicitWidth: visible ? row.implicitWidth + Style.widgets.padding * 2 : 0
    implicitHeight: Style.bar.height

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Style.widgets.spacing

        BatteryIcon {
            level: root.device.percentage
            color: root.levelColor
            anchors.verticalCenter: parent.verticalCenter
        }

        Icon {
            visible: root.charging || root.full
            text: Icons.zap
            font.pixelSize: Style.text.smallSize
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
