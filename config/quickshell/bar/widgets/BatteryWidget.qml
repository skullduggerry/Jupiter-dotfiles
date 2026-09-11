// bar/widgets/BatteryWidget.qml
import QtQuick
import Quickshell.Services.UPower
import "../../style"

Item {
    id: root
    visible: UPower.displayDevice.isLaptopBattery
    implicitWidth: visible ? row.implicitWidth + 16 : 0
    implicitHeight: Style.bar.height

    readonly property var device: UPower.displayDevice
    readonly property bool charging: !UPower.onBattery
    readonly property int pct: Math.round(device.percentage)

    // Font Awesome battery glyphs (bundled in most Nerd Fonts alongside the
    // Material Design set used in BluetoothWidget). Swap for nf-md-battery-*
    // codepoints if you want the two widgets to share one icon family.
    readonly property string icon: {
        if (charging) return "\uf0e7"   // bolt
        if (pct >= 80) return "\uf240"  // battery full
        if (pct >= 55) return "\uf241"  // battery three-quarters
        if (pct >= 30) return "\uf242"  // battery half
        if (pct >= 15) return "\uf243"  // battery quarter
        return "\uf244"                 // battery empty
    }

    readonly property color iconColor: {
        if (charging) return Colors.battery.charging
        if (pct <= 15) return Colors.battery.critical
        if (pct <= 30) return Colors.battery.low
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
            font.pixelSize: Style.text.size + 2
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.pct + "%"
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.size
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
