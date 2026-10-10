import "../panels"
import "../style"
import QtQuick
import Quickshell.Bluetooth

// Whether other devices can find this computer, which pairing from their side
// (a phone, say) needs, then the quick settings' Bluetooth page.
Item {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter

    Section {
        id: visibility

        visible: root.adapter !== null
        title: "VISIBLE TO OTHER DEVICES"

        anchors {
            top: parent.top
            left: parent.left
            leftMargin: Style.settings.padding
        }

        Row {
            spacing: Style.settings.spacing

            PillGroup {
                current: root.adapter !== null && root.adapter.discoverable
                onPicked: on => {
                    root.adapter.discoverable = on;
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.adapter !== null ? "As " + root.adapter.name : ""
                textFormat: Text.PlainText
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
            }
        }
    }

    PanelCard {
        preferredHeight: bluetooth.implicitHeight

        anchors {
            top: visibility.visible ? visibility.bottom : parent.top
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            topMargin: visibility.visible ? Style.settings.spacing : 0
        }

        BluetoothPanel {
            id: bluetooth

            anchors.fill: parent
            active: true
        }
    }
}
