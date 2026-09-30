import "../../icons"
import "../../style"
import QtQuick
import Quickshell.Networking

Item {
    id: root

    required property QuickPager pager
    readonly property WifiDevice device: Networking.devices.values.find(candidate => candidate.type === DeviceType.Wifi) || null
    readonly property WifiNetwork activeNetwork: root.device ? (root.device.networks.values.find(network => network.connected) || null) : null
    readonly property list<string> ramp: [Icons.wifiLow, Icons.wifiHigh, Icons.wifi]
    readonly property string glyph: {
        if (!Networking.wifiEnabled || !root.device)
            return Icons.wifiOff;

        if (root.activeNetwork === null)
            return Icons.wifiZero;

        return root.ramp[Math.min(root.ramp.length - 1, Math.floor(root.activeNetwork.signalStrength * root.ramp.length))];
    }

    visible: root.device !== null
    implicitWidth: visible ? icon.implicitWidth + Style.widgets.padding * 2 : 0
    implicitHeight: Style.bar.height

    Icon {
        id: icon

        anchors.centerIn: parent
        text: root.glyph
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.pager.toggleAt(root.pager.pageWifi, root)
    }
}
