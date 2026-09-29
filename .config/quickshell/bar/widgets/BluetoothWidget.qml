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

    Text {
        id: icon

        anchors.centerIn: parent
        text: !root.powered ? "\u{F00B2}" : root.connected ? "\u{F00B1}" : "\u{F00AF}"
        color: Colors.icon.active
        font.family: Style.text.font
        font.pixelSize: Style.text.iconSize
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.pager.toggleAt(root.pager.pageBluetooth, root)
    }
}
