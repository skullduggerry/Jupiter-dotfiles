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

    // Scan only while the popup is actually open. The previous version turned
    // the scanner on from the click handler and never turned it off, leaving
    // the adapter scanning forever for a list nobody was looking at.
    Binding {
        target: root.device
        property: "scannerEnabled"
        value: wifiPopup.visible
        when: root.device !== null
    }

    WidgetPopup {
        id: wifiPopup
        screen: root.screen
        namespaceSuffix: "wifi-popup"
        popupWidth: Style.popup.width
        popupHeight: Style.popup.maxHeight

        // Last connection failure. Connecting to a network whose PSK
        // NetworkManager doesn't already know fails with NoSecrets, and
        // there's no password prompt yet (TODO.md Phase 3) — so say so
        // instead of appearing to do nothing.
        property string errorText: ""
        onVisibleChanged: if (!visible) wifiPopup.errorText = ""

        Item {
            anchors.fill: parent
            anchors.margins: Style.bar.padding

            Item {
                id: header
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: Style.popup.itemHeight

                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "Wi-Fi"
                    color: Colors.text.base
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size
                }

                Text {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: !Networking.wifiHardwareEnabled ? "Blocked"
                        : Networking.wifiEnabled ? "On"
                        : "Off"
                    color: Networking.wifiEnabled ? Colors.wifi.connected : Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize

                    MouseArea {
                        anchors.fill: parent
                        enabled: Networking.wifiHardwareEnabled
                        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                }
            }

            Rectangle {
                id: separator
                anchors { top: header.bottom; left: parent.left; right: parent.right }
                height: Style.border.width
                color: Colors.base.border
            }

            Text {
                id: status
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                visible: wifiPopup.errorText !== ""
                height: visible ? implicitHeight : 0
                text: wifiPopup.errorText
                color: Colors.status.error
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
                wrapMode: Text.Wrap
            }

            ListView {
                id: networkList
                anchors {
                    top: separator.bottom
                    bottom: status.top
                    left: parent.left
                    right: parent.right
                    topMargin: Style.bar.spacing
                }
                clip: true
                model: root.device ? root.device.networks : null
                visible: count > 0

                delegate: Row {
                    id: networkRow
                    required property WifiNetwork modelData

                    width: networkList.width
                    height: Style.popup.itemHeight
                    spacing: Style.widgets.spacing

                    Connections {
                        target: networkRow.modelData
                        function onConnectionFailed(reason) {
                            wifiPopup.errorText = reason === ConnectionFailReason.NoSecrets
                                ? networkRow.modelData.name + ": password required (not supported yet)"
                                : networkRow.modelData.name + ": " + ConnectionFailReason.toString(reason)
                        }
                    }

                    Text {
                        id: networkIcon
                        text: networkRow.modelData.connected ? "󰸞" : ""
                        color: Colors.wifi.connected
                        font.family: Style.text.font
                        font.pixelSize: Style.text.size
                        width: Style.popup.rowIconWidth
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: networkRow.modelData.name
                        color: Colors.text.base
                        font.family: Style.text.font
                        font.pixelSize: Style.text.size
                        elide: Text.ElideRight
                        width: networkRow.width - networkIcon.width - networkAction.width - networkRow.spacing * 2
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        id: networkAction
                        text: networkRow.modelData.stateChanging ? "…"
                            : networkRow.modelData.connected ? "Disconnect"
                            : "Connect"
                        color: Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.smallSize
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            enabled: !networkRow.modelData.stateChanging
                            onClicked: {
                                wifiPopup.errorText = ""
                                if (networkRow.modelData.connected) networkRow.modelData.disconnect()
                                else networkRow.modelData.connect()
                            }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: networkList.count === 0
                text: Networking.wifiEnabled ? "No networks found" : "Wi-Fi is off"
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.size
            }
        }
    }
}
