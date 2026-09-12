// bar/widgets/BatteryWidget.qml
import QtQuick
import Quickshell.Services.UPower
import "../../style"

Item {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice

    visible: device.isLaptopBattery
    implicitWidth: visible ? row.implicitWidth + Style.widgets.padding * 2 : 0
    implicitHeight: Style.bar.height

    // UPowerDevice.percentage is a 0.0-1.0 ratio (energy / energyCapacity),
    // not a 0-100 number: Quickshell scales UPower's wire value by 0.01. The
    // previous Math.round(percentage) therefore always produced 0 or 1, so
    // the bar read "0%"/"1%" and every tier below picked the empty glyph.
    readonly property int percent: Math.round(device.percentage * 100)

    // Charge state comes from the device itself. `!UPower.onBattery` only
    // says AC is present, so a laptop sitting at 100% on the charger showed
    // the charging bolt indefinitely.
    readonly property bool charging: device.state === UPowerDeviceState.Charging
        || device.state === UPowerDeviceState.PendingCharge
    readonly property bool full: device.state === UPowerDeviceState.FullyCharged

    // Font Awesome battery glyphs (bundled in most Nerd Fonts alongside the
    // Material Design set used in BluetoothWidget). Swap for nf-md-battery-*
    // codepoints if you want the two widgets to share one icon family.
    readonly property string icon: {
        if (charging) return "\uf0e7"   // bolt
        if (percent >= 80) return "\uf240"  // battery full
        if (percent >= 55) return "\uf241"  // battery three-quarters
        if (percent >= 30) return "\uf242"  // battery half
        if (percent >= 15) return "\uf243"  // battery quarter
        return "\uf244"                 // battery empty
    }

    readonly property color iconColor: {
        if (charging || full) return Colors.battery.charging
        if (percent <= 15) return Colors.battery.critical
        if (percent <= 30) return Colors.battery.low
        return Colors.battery.normal
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Style.widgets.spacing

        Text {
            text: root.icon
            color: root.iconColor
            font.family: Style.text.font
            font.pixelSize: Style.text.iconSize
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.percent + "%"
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.size
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
