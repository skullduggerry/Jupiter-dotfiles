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
    readonly property list<string> ramp: ["\u{F008E}", "\u{F007A}", "\u{F007B}", "\u{F007C}", "\u{F007D}", "\u{F007E}", "\u{F007F}", "\u{F0080}", "\u{F0081}", "\u{F0082}", "\u{F0079}"]
    readonly property list<string> chargingRamp: ["\u{F089F}", "\u{F089C}", "\u{F0086}", "\u{F0087}", "\u{F0088}", "\u{F089D}", "\u{F0089}", "\u{F089E}", "\u{F008A}", "\u{F008B}", "\u{F0085}"]
    readonly property string icon: {
        const step = Math.round(Math.max(0, Math.min(1, root.device.percentage)) * (root.ramp.length - 1));
        return root.charging || root.full ? root.chargingRamp[step] : root.ramp[step];
    }
    // Colour only for the states that want acting on, as the usage meters do;
    // charging is in the glyph.
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
