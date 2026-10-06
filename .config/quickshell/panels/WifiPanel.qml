pragma ComponentBehavior: Bound

import "../icons"
import "../style"
import QtQuick
import Quickshell.Networking

PanelFrame {
    id: root

    required property bool active
    implicitHeight: root.chromeHeight + prompt.height + Math.max(Style.popup.itemHeight, networkList.contentHeight) + status.height
    readonly property WifiDevice device: Networking.devices.values.find(candidate => candidate.type === DeviceType.Wifi) || null
    property WifiNetwork pskNetwork: null
    property string errorText: ""

    function pskCapable(network: WifiNetwork): bool {
        switch (network.security) {
        case WifiSecurityType.Sae:
        case WifiSecurityType.Wpa2Psk:
        case WifiSecurityType.WpaPsk:
        case WifiSecurityType.StaticWep:
            return true;
        default:
            return false;
        }
    }

    function promptForPsk(network: WifiNetwork) {
        root.errorText = "";
        root.pskNetwork = network;
        pskInput.text = "";
        pskInput.forceActiveFocus();
    }

    function dismissPrompt() {
        root.pskNetwork = null;
        pskInput.text = "";
        pskInput.focus = false;
    }

    function activate(network: WifiNetwork) {
        root.errorText = "";
        if (network.connected) {
            network.disconnect();
            return;
        }
        if (!network.known && root.pskCapable(network))
            root.promptForPsk(network);
        else
            network.connect();
    }

    function reportFailure(network: WifiNetwork, reason) {
        if (reason === ConnectionFailReason.NoSecrets) {
            if (root.pskCapable(network)) {
                root.promptForPsk(network);
                root.errorText = network.name + ": wrong or missing password";
                return;
            }
            root.errorText = network.name + ": needs " + WifiSecurityType.toString(network.security) + " credentials (not supported)";
            return;
        }
        root.errorText = network.name + ": " + ConnectionFailReason.toString(reason);
    }

    title: "Wi-Fi"
    // A Binding destroyed with its page leaves the scanner as it is.
    Component.onDestruction: {
        if (root.active && root.device !== null)
            root.device.scannerEnabled = false;
    }
    onActiveChanged: {
        if (!root.active) {
            root.dismissPrompt();
            root.errorText = "";
        }
    }

    // Only a shown panel touches the scanner: the pagers build every page up
    // front, and an unseen one turned it off under a shown one.
    Binding {
        target: root.device
        property: "scannerEnabled"
        value: true
        when: root.active && root.device !== null
    }

    Item {
        id: prompt

        visible: root.pskNetwork !== null
        height: visible ? Style.popup.itemHeight + Style.bar.spacing : 0

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        Icon {
            id: promptIcon

            text: Icons.key
            color: Colors.text.muted
            font.pixelSize: Style.text.size
            width: Style.popup.rowIconWidth

            anchors {
                left: parent.left
                verticalCenter: pskInput.verticalCenter
            }
        }

        TextInput {
            id: pskInput

            height: Style.popup.itemHeight
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.size
            echoMode: TextInput.Password
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            Keys.onReturnPressed: {
                const network = root.pskNetwork;
                root.pskNetwork = null;
                network.connectWithPsk(pskInput.text);
                pskInput.text = "";
            }
            Keys.onEscapePressed: event => {
                if (root.pskNetwork === null) {
                    event.accepted = false;
                    return;
                }
                root.dismissPrompt();
            }

            anchors {
                top: parent.top
                left: promptIcon.right
                right: parent.right
                leftMargin: Style.widgets.spacing
            }

            Text {
                anchors.fill: parent
                visible: pskInput.text === ""
                text: root.pskNetwork ? "Password for " + root.pskNetwork.name : ""
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Item {
        id: status

        height: statusLabel.visible ? statusLabel.implicitHeight + Style.bar.spacing : 0

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        Text {
            id: statusLabel

            anchors.bottom: parent.bottom
            width: parent.width
            visible: root.errorText !== ""
            text: root.errorText
            color: Colors.status.error
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            wrapMode: Text.Wrap
        }
    }

    ListView {
        id: networkList

        clip: true
        flickableDirection: Flickable.VerticalFlick
        model: root.device ? root.device.networks : null

        anchors {
            top: prompt.bottom
            bottom: status.top
            left: parent.left
            right: parent.right
        }

        delegate: Item {
            id: networkRow

            required property WifiNetwork modelData
            readonly property bool connected: networkRow.modelData !== null && networkRow.modelData.connected
            readonly property bool known: networkRow.modelData !== null && networkRow.modelData.known
            readonly property bool stateChanging: networkRow.modelData !== null && networkRow.modelData.stateChanging
            readonly property string networkName: networkRow.modelData !== null ? networkRow.modelData.name : ""

            width: networkList.width
            height: Style.popup.itemHeight

            Connections {
                function onConnectionFailed(reason) {
                    root.reportFailure(networkRow.modelData, reason);
                }

                target: networkRow.modelData
            }

            Icon {
                id: networkIcon

                width: Style.popup.rowIconWidth
                text: networkRow.connected ? Icons.check : networkRow.known ? Icons.wifi : ""
                font.pixelSize: Style.text.size

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }

            Text {
                text: networkRow.networkName
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size
                elide: Text.ElideRight

                anchors {
                    left: networkIcon.right
                    right: networkAction.left
                    leftMargin: Style.widgets.spacing
                    rightMargin: Style.widgets.spacing
                    verticalCenter: parent.verticalCenter
                }
            }

            TextButton {
                id: networkAction

                enabled: !networkRow.stateChanging
                text: networkRow.stateChanging ? "…" : networkRow.connected ? "Disconnect" : "Connect"
                onClicked: root.activate(networkRow.modelData)

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Text {
        anchors.centerIn: networkList
        visible: networkList.count === 0
        text: Networking.wifiEnabled ? "No networks found" : "Wi-Fi is off"
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.size
    }

    trailing: [
        TextButton {
            enabled: Networking.wifiHardwareEnabled
            text: !Networking.wifiHardwareEnabled ? "Blocked" : Networking.wifiEnabled ? "On" : "Off"
            color: Networking.wifiEnabled ? Colors.wifi.connected : Colors.text.muted
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
        },
        AppletButton {
            command: ["nm-connection-editor"]
        }
    ]
}
