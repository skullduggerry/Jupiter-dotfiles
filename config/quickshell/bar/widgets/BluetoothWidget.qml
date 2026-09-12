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

    implicitWidth: row.implicitWidth + Style.widgets.padding * 2
    implicitHeight: Style.bar.height

    // Is at least one device currently connected? Bluetooth.devices is a
    // Quickshell ObjectModel, whose contents are reached through `values`.
    // The old `devices.count` / `devices.get(i)` loop read undefined and so
    // never ran — the icon was stuck on "disconnected" no matter what.
    readonly property bool connected: Bluetooth.devices.values.some(device => device.connected)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Style.widgets.spacing

        Text {
            text: root.connected ? "󰂱" : "󰂲"
            color: root.connected ? Colors.bluetooth.connected : Colors.bluetooth.disconnected
            font.family: Style.text.font
            font.pixelSize: Style.text.iconSize
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
        popupHeight: Math.max(Style.popup.minHeight,
                              Math.min(Style.popup.maxHeight,
                                       deviceList.contentHeight + Style.bar.padding * 2))

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
                    id: deviceIcon
                    text: deviceRow.modelData.connected ? "󰂱"
                        : deviceRow.modelData.paired ? "󰂯"
                        : "󰂲"
                    color: deviceRow.modelData.pairing ? Colors.bluetooth.pairing
                        : deviceRow.modelData.connected ? Colors.bluetooth.connected
                        : deviceRow.modelData.paired ? Colors.text.base
                        : Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size
                    width: Style.popup.rowIconWidth
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: deviceRow.modelData.name
                    color: Colors.text.base
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size
                    elide: Text.ElideRight
                    // Whatever the glyph and the inline action don't use.
                    width: deviceRow.width - deviceIcon.width - deviceAction.width - deviceRow.spacing * 2
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: deviceAction
                    text: deviceRow.modelData.pairing ? "Pairing…"
                        : deviceRow.modelData.connected ? "Disconnect"
                        : deviceRow.modelData.paired ? "Connect"
                        : "Pair"
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        // A pairing attempt is already in flight; let it finish
                        // or be cancelled from the system's agent.
                        enabled: !deviceRow.modelData.pairing
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
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }
    }
}
