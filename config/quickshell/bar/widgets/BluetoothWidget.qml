// bar/widgets/BluetoothWidget.qml
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../../style"

Item {
    id: root

    // Passed down from BarContent.qml so the popup opens on the correct
    // monitor in multi-monitor setups (see WidgetPopup.qml / Bar.qml).
    required property ShellScreen screen

    implicitWidth: row.implicitWidth + 16
    implicitHeight: Style.bar.height

    // Is at least one device currently connected?
    readonly property bool connected: {
        for (let i = 0; i < Bluetooth.devices.count; i++) {
            if (Bluetooth.devices.get(i).connected) return true
        }
        return false
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.connected ? "󰂱" : "󰂲"
            color: root.connected ? Colors.bluetooth.connected : Colors.bluetooth.disconnected
            font.family: Style.text.font
            font.pixelSize: Style.text.size + 2
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: btPopup.visible = !btPopup.visible
    }

    // Device list with connect/disconnect/pair actions. Click-outside-to-
    // close and the popup chrome now live in the shared WidgetPopup
    // component (see bar/widgets/WidgetPopup.qml) instead of being
    // hand-rolled per widget.
    WidgetPopup {
        id: btPopup
        screen: root.screen
        namespaceSuffix: "bt-popup"
        popupWidth: Style.popup.width
        popupHeight: Math.min(Style.popup.maxHeight, deviceList.contentHeight + Style.bar.padding * 2)

        ListView {
            id: deviceList
            anchors.fill: parent
            anchors.margins: Style.bar.padding
            clip: true
            model: Bluetooth.devices
            visible: count > 0

            delegate: Row {
                id: deviceRow
                required property BluetoothDevice modelData

                width: deviceList.width
                height: Style.popup.itemHeight
                spacing: Style.widgets.spacing

                Text {
                    text: deviceRow.modelData.connected ? "󰂱"
                        : deviceRow.modelData.paired ? "󰂯"
                        : "󰂲"
                    color: deviceRow.modelData.connected ? Colors.bluetooth.connected
                        : deviceRow.modelData.paired ? Colors.text.base
                        : Colors.bluetooth.pairing
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: deviceRow.modelData.name
                    color: Colors.text.base
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size
                    elide: Text.ElideRight
                    width: deviceRow.width - 90
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: deviceRow.modelData.connected ? "Disconnect"
                        : deviceRow.modelData.paired ? "Connect"
                        : "Pair"
                    color: Colors.base.border
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size - 2
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (deviceRow.modelData.connected) deviceRow.modelData.disconnect()
                            else if (deviceRow.modelData.paired) deviceRow.modelData.connect()
                            else deviceRow.modelData.pair()
                        }
                    }
                }
            }
        }

        Text {
            visible: deviceList.count === 0
            anchors.centerIn: parent
            text: "No devices found"
            color: Colors.base.border
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }
    }
}
