import "../../style"
import QtQuick
import Quickshell.Networking

Item {
    id: root

    required property QuickPager pager
    readonly property WifiDevice device: Networking.devices.values.find(candidate => candidate.type === DeviceType.Wifi) || null
    readonly property WifiNetwork activeNetwork: root.device ? (root.device.networks.values.find(network => network.connected) || null) : null
    readonly property list<string> ramp: ["\u{F091F}", "\u{F0922}", "\u{F0925}", "\u{F0928}"]
    readonly property string glyph: {
        if (!Networking.wifiEnabled || !root.device)
            return "\u{F092E}";

        if (root.activeNetwork === null)
            return "\u{F092F}";

        return root.ramp[Math.min(root.ramp.length - 1, Math.floor(root.activeNetwork.signalStrength * root.ramp.length))];
    }

    visible: root.device !== null
    implicitWidth: visible ? icon.implicitWidth + Style.widgets.padding * 2 : 0
    implicitHeight: Style.bar.height

    Text {
        id: icon

        anchors.centerIn: parent
        text: root.glyph
        color: Colors.icon.active
        font.family: Style.text.font
        font.pixelSize: Style.text.iconSize
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.pager.toggleAt(root.pager.pageWifi, root)
    }
}
