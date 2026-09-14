import "../../panels"
import "../../style"
import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Wayland

Item {
    id: root

    required property ShellScreen screen
    required property QuickPager pager
    readonly property WifiDevice device: Networking.devices.values.find((candidate) => {
        return candidate.type === DeviceType.Wifi;
    }) || null
    readonly property WifiNetwork activeNetwork: root.device ? (root.device.networks.values.find((network) => {
        return network.connected;
    }) || null) : null
    readonly property bool connected: activeNetwork !== null
    readonly property string icon: {
        if (!Networking.wifiEnabled || !root.device)
            return "󰤮";

        if (!root.connected)
            return "󰤯";

        const strength = root.activeNetwork.signalStrength;
        if (strength > 0.75)
            return "󰤨";

        if (strength > 0.5)
            return "󰤥";

        if (strength > 0.25)
            return "󰤢";

        return "󰤟";
    }

    visible: device !== null
    implicitWidth: visible ? row.implicitWidth + Style.widgets.padding * 2 : 0
    implicitHeight: Style.bar.height

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Style.widgets.spacing

        Text {
            text: root.icon
            color: root.connected ? Colors.icon.active : Colors.icon.disabled
            font.family: Style.text.font
            font.pixelSize: Style.text.iconSize
            anchors.verticalCenter: parent.verticalCenter
        }

    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.pager.toggleAt(root.pager.pageWifi, root)
    }

}
