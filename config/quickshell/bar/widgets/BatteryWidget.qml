import QtQuick
import Quickshell.Services.UPower
import "../../style"

Item{
	visible: UPower.displayDevice.isLaptopBattery
	implicitWidth: visible ? row.implicitWidth + 16 : 0
   	implicitHeight: Style.bar.height

    	readonly property var device: UPower.displayDevice
    	readonly property bool charging: !UPower.onBattery
    	readonly property int  pct:	Math.round(device.percentage)
	
	readonly property string icon: {
	if (charging) return "charging"
	return "temp"
	}

	Row{
		id: row
		anchors.centerIn: parent
		spacing: Style.widgets.spacing

		Text {
            text: parent.parent.icon
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.size + 2
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: parent.parent.pct + "%"
            color: Colors.text
            font.family: Style.text.font
            font.pixelSize: Style.text.size
            anchors.verticalCenter: parent.verticalCenter
        }
	}

}
