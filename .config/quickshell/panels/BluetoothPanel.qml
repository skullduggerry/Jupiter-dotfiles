pragma ComponentBehavior: Bound

import "../icons"
import "../style"
import QtQuick
import Quickshell.Bluetooth

// The paired devices, connected ones first, then the ones found nearby, which
// the adapter searches for while this is shown. A device paired here is
// trusted, so it can reconnect by itself, and connected; Forget unpairs, on a
// second click.
PanelFrame {
    id: root

    required property bool active
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool powered: root.adapter !== null && root.adapter.enabled
    readonly property var devices: Bluetooth.devices.values.filter(device => device.paired || device.deviceName !== "").sort((left, right) => right.connected - left.connected || right.paired - left.paired || left.name.localeCompare(right.name))
    implicitHeight: root.chromeHeight + Math.max(Style.popup.itemHeight, deviceList.contentHeight)
    property BluetoothDevice pairingDevice: null
    property BluetoothDevice forgetting: null

    function pair(device: BluetoothDevice) {
        root.pairingDevice = device;
        device.pair();
    }

    title: "Bluetooth"
    onActiveChanged: root.forgetting = null
    // A Binding destroyed with its page leaves its target as it is, and BlueZ
    // would go on searching for as long as the shell runs.
    Component.onDestruction: {
        if (search.when)
            root.adapter.discovering = false;
    }
    trailing: [
        Text {
            visible: root.powered && root.adapter.discovering
            text: "Searching…"
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
        },
        TextButton {
            id: power

            visible: root.adapter !== null
            enabled: root.adapter !== null && root.adapter.state !== BluetoothAdapterState.Blocked
            text: !power.enabled ? "Blocked" : root.powered ? "On" : "Off"
            color: root.powered ? Colors.accent.primary : Colors.text.muted
            onClicked: root.adapter.enabled = !root.powered
        },
        AppletButton {
            command: ["blueman-manager"]
        }
    ]

    // On the adapter's state, not `enabled`: that turns true as soon as it is
    // written, and BlueZ refuses a search until the radio is actually up.
    Binding {
        id: search

        target: root.adapter
        property: "discovering"
        value: true
        when: root.active && root.adapter !== null && root.adapter.state === BluetoothAdapterState.Enabled
    }

    Connections {
        function onPairedChanged() {
            if (!root.pairingDevice.paired)
                return;

            root.pairingDevice.trusted = true;
            root.pairingDevice.connect();
            root.pairingDevice = null;
        }

        target: root.pairingDevice
    }

    Timer {
        running: root.forgetting !== null
        interval: Style.popup.confirmTimeout
        onTriggered: root.forgetting = null
    }

    ListView {
        id: deviceList

        anchors.fill: parent
        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        model: root.devices

        delegate: Item {
            id: row

            required property BluetoothDevice modelData
            readonly property bool busy: row.modelData.pairing || row.modelData.state === BluetoothDeviceState.Connecting || row.modelData.state === BluetoothDeviceState.Disconnecting

            width: deviceList.width
            height: Style.popup.itemHeight

            Icon {
                id: icon

                width: Style.popup.rowIconWidth
                text: row.modelData.connected ? Icons.bluetoothConnected : row.modelData.paired ? Icons.bluetooth : Icons.bluetoothOff
                font.pixelSize: Style.text.size

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }

            Text {
                text: row.modelData.name + (row.modelData.connected && row.modelData.batteryAvailable ? "  " + Math.round(row.modelData.battery * 100) + "%" : "")
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size
                elide: Text.ElideRight

                anchors {
                    left: icon.right
                    right: actions.left
                    leftMargin: Style.widgets.spacing
                    rightMargin: Style.bar.spacing
                    verticalCenter: parent.verticalCenter
                }
            }

            Row {
                id: actions

                spacing: Style.bar.spacing

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                Text {
                    visible: row.busy
                    text: row.modelData.pairing ? "Pairing…" : "…"
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                }

                TextButton {
                    visible: row.modelData.pairing
                    text: "Cancel"
                    onClicked: row.modelData.cancelPair()
                }

                TextButton {
                    visible: !row.busy && root.powered
                    text: row.modelData.connected ? "Disconnect" : row.modelData.paired ? "Connect" : "Pair"
                    onClicked: {
                        if (row.modelData.connected)
                            row.modelData.disconnect();
                        else if (row.modelData.paired)
                            row.modelData.connect();
                        else
                            root.pair(row.modelData);
                    }
                }

                TextButton {
                    id: forget

                    visible: row.modelData.paired && !row.busy
                    text: root.forgetting === row.modelData ? "Forget?" : "Forget"
                    color: root.forgetting === row.modelData ? Colors.status.error : forget.hovered ? Colors.text.base : Colors.text.muted
                    onClicked: {
                        if (root.forgetting === row.modelData)
                            row.modelData.forget();
                        else
                            root.forgetting = row.modelData;
                    }
                }
            }
        }
    }

    Text {
        anchors.centerIn: deviceList
        visible: deviceList.count === 0
        text: {
            if (root.adapter === null)
                return "No Bluetooth adapter";

            if (!root.powered)
                return "Bluetooth is off";

            return root.adapter.discovering ? "Searching for devices…" : "No devices found";
        }
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.size
    }
}
