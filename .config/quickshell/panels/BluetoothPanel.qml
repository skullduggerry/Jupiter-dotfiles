import "../style"
import QtQuick
import Quickshell.Bluetooth

Item {
    id: root

    readonly property int preferredHeight: Style.bar.padding * 2 + header.height + Style.border.width + Style.bar.spacing + Style.popup.maxHeight

    Item {
        anchors.fill: parent
        anchors.margins: Style.bar.padding

        Item {
            id: header

            height: Style.popup.itemHeight

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            Text {
                text: "Bluetooth"
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

            }

        }

        Rectangle {
            id: separator

            height: Style.border.width
            color: Colors.base.border

            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
            }

        }

        ListView {
            id: deviceList

            clip: true
            flickableDirection: Flickable.VerticalFlick
            model: Bluetooth.devices
            visible: count > 0

            anchors {
                top: separator.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.bar.spacing
            }

            delegate: Row {
                id: deviceRow

                required property BluetoothDevice modelData
                readonly property bool connected: deviceRow.modelData !== null && deviceRow.modelData.connected
                readonly property bool paired: deviceRow.modelData !== null && deviceRow.modelData.paired
                readonly property bool pairing: deviceRow.modelData !== null && deviceRow.modelData.pairing
                readonly property string deviceName: deviceRow.modelData !== null ? deviceRow.modelData.name : ""

                width: deviceList.width
                height: Style.popup.itemHeight
                spacing: Style.widgets.spacing

                Text {
                    id: deviceIcon

                    text: deviceRow.connected ? "󰂱" : deviceRow.paired ? "󰂯" : "󰂲"
                    color: deviceRow.connected ? Colors.icon.active : deviceRow.paired ? Colors.icon.inactive : Colors.icon.disabled
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size
                    width: Style.popup.rowIconWidth
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: deviceRow.deviceName
                    color: Colors.text.base
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size
                    elide: Text.ElideRight
                    width: deviceRow.width - deviceIcon.width - deviceAction.width - deviceRow.spacing * 2
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: deviceAction

                    text: deviceRow.pairing ? "Pairing…" : deviceRow.connected ? "Disconnect" : deviceRow.paired ? "Connect" : "Pair"
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        enabled: !deviceRow.pairing
                        onClicked: {
                            if (deviceRow.connected)
                                deviceRow.modelData.disconnect();
                            else if (deviceRow.paired)
                                deviceRow.modelData.connect();
                            else
                                deviceRow.modelData.pair();
                        }
                    }

                }

            }

        }

        Text {
            anchors.centerIn: parent
            visible: deviceList.count === 0
            text: "No devices found"
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }

    }

}
