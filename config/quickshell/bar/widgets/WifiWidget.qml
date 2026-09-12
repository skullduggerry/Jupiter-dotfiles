// bar/widgets/WifiWidget.qml
import QtQuick
import Quickshell
import Quickshell.Networking
import "../../style"

Item {
    id: root

    required property ShellScreen screen

    // First Wi-Fi capable device on the system. Multi-adapter Wi-Fi setups
    // aren't handled here, mirroring BluetoothWidget's single-adapter
    // assumption (Bluetooth.devices is already adapter-agnostic).
    readonly property WifiDevice device: {
        for (let i = 0; i < Networking.devices.count; i++) {
            const candidate = Networking.devices.get(i)
            if (candidate.type === DeviceType.Wifi) return candidate
        }
        return null
    }

    readonly property WifiNetwork activeNetwork: {
        if (!device) return null
        for (let i = 0; i < device.networks.count; i++) {
            const network = device.networks.get(i)
            if (network.connected) return network
        }
        return null
    }

    readonly property bool connected: activeNetwork !== null

    visible: device !== null
    implicitWidth: visible ? row.implicitWidth + 16 : 0
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
        spacing: 4

        Text {
            text: root.icon
            color: root.connected ? Colors.wifi.connected : Colors.wifi.disconnected
            font.family: Style.text.font
            font.pixelSize: Style.text.size + 2
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            // Kick off a scan so the list is fresh when the popup opens.
            if (root.device) root.device.scannerEnabled = true
            wifiPopup.visible = !wifiPopup.visible
        }
    }

    WidgetPopup {
        id: wifiPopup
        screen: root.screen
        namespaceSuffix: "wifi-popup"
        popupWidth: Style.popup.width
        popupHeight: Style.popup.maxHeight

        Column {
            anchors.fill: parent
            anchors.margins: Style.bar.padding
            spacing: Style.bar.spacing

            Text {
                text: Networking.wifiEnabled ? "Wi-Fi" : "Wi-Fi (off)"
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Colors.base.border
            }

            ListView {
                id: networkList
                width: parent.width
                height: parent.height - 40
                clip: true
                model: root.device ? root.device.networks : null
                visible: root.device !== null && count > 0

                delegate: Row {
                    id: networkRow
                    required property WifiNetwork modelData

                    width: networkList.width
                    height: Style.popup.itemHeight
                    spacing: Style.widgets.spacing

                    Text {
                        text: networkRow.modelData.connected ? "󰸞" : ""
                        color: Colors.wifi.connected
                        font.family: Style.text.font
                        font.pixelSize: Style.text.size
                        width: 16
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: networkRow.modelData.name
                        color: Colors.text.base
                        font.family: Style.text.font
                        font.pixelSize: Style.text.size
                        elide: Text.ElideRight
                        width: networkRow.width - 60
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: networkRow.modelData.connected ? "Disconnect" : "Connect"
                        color: Colors.base.border
                        font.family: Style.text.font
                        font.pixelSize: Style.text.size - 2
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                // Networks requiring a PSK that isn't already
                                // known will emit Network.connectionFailed()
                                // with NoSecrets; entering a new PSK isn't
                                // wired up yet (Phase 3 candidate).
                                if (networkRow.modelData.connected) networkRow.modelData.disconnect()
                                else networkRow.modelData.connect()
                            }
                        }
                    }
                }
            }

            Text {
                visible: !root.device || root.device.networks.count === 0
                text: "No networks found"
                color: Colors.base.border
                font.family: Style.text.font
                font.pixelSize: Style.text.size
            }
        }
    }
}
