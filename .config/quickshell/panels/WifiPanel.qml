// panels/WifiPanel.qml
import QtQuick
import Quickshell.Networking
import "../style"

Item {
    id: root

    required property bool active

    readonly property bool wantsKeyboard: root.pskNetwork !== null

    readonly property int preferredHeight: Style.bar.padding * 2
        + header.height
        + Style.border.width
        + prompt.height
        + Style.bar.spacing
        + Math.max(Style.popup.itemHeight, networkList.contentHeight)
        + status.height

    readonly property WifiDevice device: Networking.devices.values.find(candidate => candidate.type === DeviceType.Wifi) || null

    property WifiNetwork pskNetwork: null

    property string errorText: ""

    function pskCapable(network: WifiNetwork): bool {
        switch (network.security) {
        case WifiSecurityType.Sae:
        case WifiSecurityType.Wpa2Psk:
        case WifiSecurityType.WpaPsk:
        case WifiSecurityType.StaticWep:
            return true
        default:
            return false
        }
    }

    function promptForPsk(network: WifiNetwork) {
        root.errorText = ""
        root.pskNetwork = network
        pskInput.text = ""
        pskInput.forceActiveFocus()
    }

    function dismissPrompt() {
        root.pskNetwork = null
        pskInput.text = ""
        pskInput.focus = false
    }

    function activate(network: WifiNetwork) {
        root.errorText = ""
        if (network.connected) {
            network.disconnect()
            return
        }
        if (!network.known && root.pskCapable(network)) root.promptForPsk(network)
        else network.connect()
    }

    function reportFailure(network: WifiNetwork, reason) {
        if (reason === ConnectionFailReason.NoSecrets) {
            if (root.pskCapable(network)) {
                root.promptForPsk(network)
                root.errorText = network.name + ": wrong or missing password"
                return
            }
            root.errorText = network.name + ": needs "
                + WifiSecurityType.toString(network.security)
                + " credentials (not supported)"
            return
        }
        root.errorText = network.name + ": " + ConnectionFailReason.toString(reason)
    }

    Binding {
        target: root.device
        property: "scannerEnabled"
        value: root.active
        when: root.device !== null
    }

    onActiveChanged: if (!root.active) {
        root.dismissPrompt()
        root.errorText = ""
    }

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

        Item {
            id: prompt
            anchors { top: separator.bottom; left: parent.left; right: parent.right }
            visible: root.pskNetwork !== null
            height: visible ? Style.popup.itemHeight : 0

            Text {
                id: promptIcon
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "󰌆"
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.size
                width: Style.popup.rowIconWidth
            }

            TextInput {
                id: pskInput
                anchors {
                    left: promptIcon.right
                    right: parent.right
                    leftMargin: Style.widgets.spacing
                    verticalCenter: parent.verticalCenter
                }
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size
                echoMode: TextInput.Password
                clip: true

                Keys.onReturnPressed: {
                    const network = root.pskNetwork
                    root.pskNetwork = null
                    network.connectWithPsk(pskInput.text)
                    pskInput.text = ""
                }

                Keys.onEscapePressed: (event) => {
                    if (root.pskNetwork === null) {
                        event.accepted = false
                        return
                    }
                    root.dismissPrompt()
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
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: statusLabel.visible ? statusLabel.implicitHeight + Style.bar.spacing : 0

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
            anchors {
                top: prompt.bottom
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

                readonly property bool connected: networkRow.modelData !== null && networkRow.modelData.connected
                readonly property bool known: networkRow.modelData !== null && networkRow.modelData.known
                readonly property bool stateChanging: networkRow.modelData !== null && networkRow.modelData.stateChanging
                readonly property string networkName: networkRow.modelData !== null ? networkRow.modelData.name : ""

                width: networkList.width
                height: Style.popup.itemHeight
                spacing: Style.widgets.spacing

                Connections {
                    target: networkRow.modelData
                    function onConnectionFailed(reason) {
                        root.reportFailure(networkRow.modelData, reason)
                    }
                }

                Text {
                    id: networkIcon
                    text: networkRow.connected ? "󰸞"
                        : networkRow.known ? "󰤨"
                        : ""
                    color: networkRow.connected ? Colors.wifi.connected : Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size
                    width: Style.popup.rowIconWidth
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: networkRow.networkName
                    color: Colors.text.base
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size
                    elide: Text.ElideRight
                    width: networkRow.width - networkIcon.width - networkAction.width - networkRow.spacing * 2
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: networkAction
                    text: networkRow.stateChanging ? "…"
                        : networkRow.connected ? "Disconnect"
                        : "Connect"
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        enabled: !networkRow.stateChanging
                        onClicked: root.activate(networkRow.modelData)
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
