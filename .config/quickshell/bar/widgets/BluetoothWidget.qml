import "../../style"
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Item {
    id: root

    required property ShellScreen screen
    required property QuickPager pager
    readonly property bool powered: Bluetooth.defaultAdapter !== null && Bluetooth.defaultAdapter.enabled
    readonly property bool connected: Bluetooth.devices.values.some((device) => {
        return device.connected;
    })

    implicitWidth: row.implicitWidth + Style.widgets.padding * 2
    implicitHeight: Style.bar.height

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Style.widgets.spacing

        Text {
            text: !root.powered ? "󰂲" : root.connected ? "󰂱" : "󰂯"
            color: Colors.icon.active
            font.family: Style.text.font
            font.pixelSize: Style.text.iconSize
            anchors.verticalCenter: parent.verticalCenter
        }

    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.pager.toggleAt(root.pager.pageBluetooth, root)
    }

}
