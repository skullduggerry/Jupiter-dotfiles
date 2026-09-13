// bar/widgets/WifiPanel.qml
//
// The Wi-Fi network list: an on/off header, the scanned networks with an
// inline connect/disconnect action, a password prompt for networks
// NetworkManager has no stored secret for, and an inline error line.
//
// Extracted from WifiWidget's popup content so the gesture dropdown's right
// zone can show the same list instead of a second copy of it (see
// dropdown/Dropdown.qml). Everything it needs comes from Networking, so the
// only thing an owner has to provide is `active`.
import QtQuick
import Quickshell.Networking
import "../../style"

Item {
    id: root

    // Whether this panel is actually on screen. Gates the adapter's scanner,
    // which has no reason to run for a list nobody is looking at, and clears
    // transient state when the panel goes away. An owner must bind it
    // explicitly: an Item's own `visible` stays true inside a hidden window.
    required property bool active

    // Raised while the password prompt is up so the owning surface can take
    // keyboard focus only for as long as there's something to type into.
    readonly property bool wantsKeyboard: root.pskNetwork !== null

    // First Wi-Fi capable device on the system. Multi-adapter Wi-Fi setups
    // aren't handled here, mirroring BluetoothWidget's single-adapter
    // assumption (Bluetooth.devices is already adapter-agnostic).
    readonly property WifiDevice device: Networking.devices.values.find(candidate => candidate.type === DeviceType.Wifi) || null

    // The network waiting for a password, or null when no prompt is up.
    property WifiNetwork pskNetwork: null

    // Last failure, shown inline rather than leaving a click looking like it
    // did nothing.
    property string errorText: ""

    // A bare pre-shared key is enough for these. Enterprise modes (EAP/LEAP,
    // and WPA3 Suite-B 192) additionally need an identity and usually a
    // certificate, and WifiNetwork only exposes connectWithPsk(), so those
    // get an honest "not supported" instead of a password box that can't
    // work. Open/OWE networks need no secret at all.
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
    }

    function activate(network: WifiNetwork) {
        root.errorText = ""
        if (network.connected) {
            network.disconnect()
            return
        }
        // A network NetworkManager has no profile for and that wants a PSK
        // can't be connected blind — ask first rather than waiting for the
        // NoSecrets failure to come back.
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

    // Scan only while the panel is on screen. An earlier version turned the
    // scanner on from a click handler and never turned it off, leaving the
    // adapter scanning forever (llm.md §15).
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

        // Password entry for the network in `pskNetwork`. Collapses to zero
        // height when there's nothing to ask for, so the list below simply
        // grows back into the space.
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
                Keys.onEscapePressed: root.dismissPrompt()

                // The prompt replaces the header's "type a password" hint, so
                // say whose password this is while the field is empty.
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

        // Wrapped in an Item that takes its height, because binding a
        // wrapping Text's own `height` to its own `implicitHeight` relayouts
        // it and loops — which the version of this line inside WifiWidget did,
        // latently, since it only ever ran with the label hidden.
        Item {
            id: status
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: statusLabel.visible ? statusLabel.implicitHeight : 0

            Text {
                id: statusLabel
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
                    text: networkRow.modelData.connected ? "󰸞"
                        : networkRow.modelData.known ? "󰤨"
                        : ""
                    color: networkRow.modelData.connected ? Colors.wifi.connected : Colors.text.muted
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
                    // Whatever the glyph and the inline action don't use.
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
