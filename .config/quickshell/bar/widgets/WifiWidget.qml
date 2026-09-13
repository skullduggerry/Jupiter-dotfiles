// bar/widgets/WifiWidget.qml
import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Wayland
import "../../panels"
import "../../style"

Item {
    id: root

    required property ShellScreen screen

    readonly property WifiDevice device: Networking.devices.values.find(candidate => candidate.type === DeviceType.Wifi) || null

    readonly property WifiNetwork activeNetwork: root.device
        ? (root.device.networks.values.find(network => network.connected) || null)
        : null

    readonly property bool connected: activeNetwork !== null

    visible: device !== null
    implicitWidth: visible ? row.implicitWidth + Style.widgets.padding * 2 : 0
    implicitHeight: Style.bar.height

    readonly property string icon: {
        if (!Networking.wifiEnabled || !root.device) return "󰤮"
        if (!root.connected) return "󰤯"
        const strength = root.activeNetwork.signalStrength
        if (strength > 0.75) return "󰤨"
        if (strength > 0.5) return "󰤥"
        if (strength > 0.25) return "󰤢"
        return "󰤟"
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Style.widgets.spacing

        Text {
            text: root.icon
            color: root.connected ? Colors.wifi.connected : Colors.wifi.disconnected
            font.family: Style.text.font
            font.pixelSize: Style.text.iconSize
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: wifiPopup.visible = !wifiPopup.visible
    }

    WidgetPopup {
        id: wifiPopup
        screen: root.screen
        anchorItem: root
        namespaceSuffix: "wifi-popup"
        popupWidth: Style.popup.width
        popupHeight: Math.max(Style.popup.minHeight,
                              Math.min(Style.popup.maxHeight, wifiPanel.preferredHeight))

        keyboardFocus: wifiPanel.wantsKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand

        WifiPanel {
            id: wifiPanel
            anchors.fill: parent
            active: wifiPopup.visible
        }
    }
}
