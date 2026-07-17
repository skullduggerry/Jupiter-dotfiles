// bar/widgets/BluetoothWidget.qml
import QtQuick
import Quickshell.Bluetooth
import "../../style"

Item {
    implicitWidth: row.implicitWidth + 16
    implicitHeight: Style.bar.height

    // is any device currently connected?
    readonly property bool connected: {
        for (let i = 0; i < Bluetooth.devices.count; i++) {
            if (Bluetooth.devices.get(i).connected) return true
        }
        return false
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: parent.parent.connected ? "󰂱" : "󰂲"
            color: parent.parent.connected ? Colors.bluetooth.connected : Colors.bluetooth.disconnected
            font.family: Style.text.font
            font.pixelSize: Style.text.size + 2
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: btPopup.visible = !btPopup.visible
    }
}
