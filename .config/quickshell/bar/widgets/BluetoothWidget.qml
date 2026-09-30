import "../../icons"
import "../../style"
import QtQuick
import Quickshell.Bluetooth

Item {
    id: root

    required property QuickPager pager
    readonly property bool powered: Bluetooth.defaultAdapter !== null && Bluetooth.defaultAdapter.enabled
    readonly property bool connected: Bluetooth.devices.values.some(device => device.connected)

    implicitWidth: icon.implicitWidth + Style.widgets.padding * 2
    implicitHeight: Style.bar.height

    Icon {
        id: icon

        anchors.centerIn: parent
        text: !root.powered ? Icons.bluetoothOff : root.connected ? Icons.bluetoothConnected : Icons.bluetooth
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.pager.toggleAt(root.pager.pageBluetooth, root)
    }
}
