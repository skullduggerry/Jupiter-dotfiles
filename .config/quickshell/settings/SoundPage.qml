pragma ComponentBehavior: Bound

import "../icons"
import "../panels"
import "../services"
import "../style"
import QtQuick
import Quickshell.Services.Pipewire

// What PipeWire has (Volume's lists): the outputs and inputs, the one in use
// chosen here and its volume, then every app playing sound with a volume of
// its own.
ScrollPage {
    id: root

    // Everything shown here, bound so their volumes and properties are live.
    PwObjectTracker {
        objects: Volume.nodes
    }

    Section {
        title: "OUTPUT"

        DeviceCard {
            devices: Volume.outputs
            chosen: Pipewire.defaultAudioSink
            emptyText: "No output device"
            onPicked: node => {
                Pipewire.preferredDefaultAudioSink = node;
            }
        }
    }

    Section {
        title: "INPUT"

        DeviceCard {
            devices: Volume.inputs
            chosen: Pipewire.defaultAudioSource
            emptyText: "No input device"
            volumeIcon: Icons.mic
            mutedIcon: Icons.micOff
            onPicked: node => {
                Pipewire.preferredDefaultAudioSource = node;
            }
        }
    }

    Section {
        title: "APPLICATIONS"

        Card {
            width: root.columnWidth
            height: appRows.implicitHeight + Style.bar.padding * 2

            Column {
                id: appRows

                spacing: Style.bar.spacing

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: Style.bar.padding
                }

                Repeater {
                    model: Volume.apps

                    delegate: AppVolumeRow {
                        id: app

                        required property PwNode modelData

                        width: appRows.width
                        node: app.modelData
                    }
                }

                Text {
                    visible: Volume.apps.length === 0
                    text: "No app is playing sound"
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                }
            }
        }
    }

    component DeviceCard: Card {
        id: card

        property var devices: []
        property PwNode chosen: null
        property string emptyText: ""
        property string volumeIcon: Icons.volume2
        property string mutedIcon: Icons.volumeX

        signal picked(PwNode node)

        width: root.columnWidth
        height: deviceRows.implicitHeight + Style.bar.padding * 2

        Column {
            id: deviceRows

            spacing: Style.widgets.spacing

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: Style.bar.padding
            }

            Repeater {
                model: card.devices

                delegate: AudioDeviceRow {
                    id: device

                    required property PwNode modelData

                    width: deviceRows.width
                    node: device.modelData
                    inUse: card.chosen !== null && card.chosen.id === device.modelData.id
                    onPicked: card.picked(device.modelData)
                }
            }

            Text {
                visible: card.devices.length === 0
                text: card.emptyText
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
            }

            Rectangle {
                visible: card.chosen !== null
                width: parent.width
                height: Style.border.width
                color: Colors.base.border
            }

            VolumeRow {
                visible: card.chosen !== null
                width: parent.width
                node: card.chosen
                volumeIcon: card.volumeIcon
                mutedIcon: card.mutedIcon
            }
        }
    }
}
