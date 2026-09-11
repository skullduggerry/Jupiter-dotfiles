// bar/widgets/BluetoothWidget.qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import "../../style"

Item {
    id: root
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

    // Minimal read-only device list. This is what was crashing before —
    // btPopup was referenced by the MouseArea above but never defined.
    // Connect/disconnect actions and pairing flow are Phase 2 work, once
    // the exact Quickshell.Bluetooth device API to call is confirmed.
    // No click-outside-to-close yet either; closing currently requires
    // clicking the widget again.
    PanelWindow {
        id: btPopup
        visible: false

        WlrLayershell.namespace: "quickshell:bt-popup"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            right: true
        }
        margins {
            top: Style.bar.topGap + Style.bar.height + 4
            right: Style.bar.sideGap
        }

        implicitWidth: 220
        implicitHeight: Math.min(260, deviceList.contentHeight + Style.bar.padding * 2)
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: Style.bar.radius
            color: Qt.rgba(Colors.base.base.r, Colors.base.base.g, Colors.base.base.b, Colors.base.opacity)
            border.color: Colors.base.border
            border.width: Style.border.width

            ListView {
                id: deviceList
                anchors.fill: parent
                anchors.margins: Style.bar.padding
                clip: true
                model: Bluetooth.devices
                visible: count > 0

                delegate: Row {
                    width: deviceList.width
                    height: 28
                    spacing: Style.widgets.spacing

                    Text {
                        text: modelData.connected ? "󰂱" : "󰂯"
                        color: modelData.connected ? Colors.bluetooth.connected : Colors.text.base
                        font.family: Style.text.font
                        font.pixelSize: Style.text.size
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: modelData.name
                        color: Colors.text.base
                        font.family: Style.text.font
                        font.pixelSize: Style.text.size
                        anchors.verticalCenter: parent.verticalCenter
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
}
