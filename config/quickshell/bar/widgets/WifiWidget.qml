// bar/widgets/WifiWidget.qml
import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Wayland
import "../../style"

Item {
    id: root

    required property ShellScreen screen

    // First Wi-Fi capable device on the system, for the bar glyph. WifiPanel
    // derives the same device for its list; both are one-line lookups off
    // Networking, which is cheaper than threading a shared object through
    // two surfaces that each work standalone.
    //
    // Quickshell's ObjectModel is read through `values`; the old
    // `Networking.devices.count` loop compared against undefined, never ran,
    // and left `device` permanently null — which hid the whole widget.
    readonly property WifiDevice device: Networking.devices.values.find(candidate => candidate.type === DeviceType.Wifi) || null

    readonly property WifiNetwork activeNetwork: root.device
        ? (root.device.networks.values.find(network => network.connected) || null)
        : null

    readonly property bool connected: activeNetwork !== null

    visible: device !== null
    implicitWidth: visible ? row.implicitWidth + Style.widgets.padding * 2 : 0
    implicitHeight: Style.bar.height

    // WifiNetwork.signalStrength is normalized to 0.0-1.0.
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
        namespaceSuffix: "wifi-popup"
        popupWidth: Style.popup.width
        popupHeight: Style.popup.maxHeight

        // Only the password prompt needs the keyboard, and it needs it
        // reliably: the popup surface maps unfocused, so a compositor that
        // hands on-demand focus out on map alone would never give this one
        // focus after the fact. Exclusive is dropped again the moment the
        // prompt is answered or dismissed.
        keyboardFocus: wifiPanel.wantsKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        WifiPanel {
            id: wifiPanel
            anchors.fill: parent
            active: wifiPopup.visible
        }
    }
}
