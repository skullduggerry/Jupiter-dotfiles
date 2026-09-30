pragma ComponentBehavior: Bound

import "../icons"
import "../panels"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets

// What PipeWire has: the outputs and inputs, the one in use chosen here and
// its volume, then every app playing sound with a volume of its own.
ScrollPage {
    id: root

    readonly property var nodes: Array.from(Pipewire.nodes.values).filter(node => node.audio !== null)
    // By PwNodeType's flags: a duplex device is an output and an input.
    readonly property var outputs: root.nodes.filter(node => !node.isStream && (node.type & PwNodeType.Sink) !== 0)
    readonly property var inputs: root.nodes.filter(node => !node.isStream && (node.type & PwNodeType.Source) !== 0)
    // Apps playing sound. A stream plays into a sink, so it carries the Sink
    // flag; a recording one carries Source instead.
    readonly property var apps: root.nodes.filter(node => node.type === PwNodeType.AudioOutStream)

    // HDMI outputs end their description in the monitor's name, which is
    // also their nickname and all that tells them apart.
    function label(node): string {
        if (node.nickname !== "" && node.description.endsWith("[" + node.nickname + "]"))
            return node.nickname;

        return node.description !== "" ? node.description : node.name;
    }

    function kind(node): string {
        const properties = node.properties || {};
        if (properties["device.api"] === "bluez5")
            return "Bluetooth";

        if (node.description.includes("HDMI") || node.description.includes("DisplayPort"))
            return "HDMI";

        if (node.description.includes("IEC958"))
            return "Digital (S/PDIF)";

        if (properties["device.bus"] === "usb")
            return "USB";

        if (properties["device.api"] === undefined)
            return "Virtual";

        return "Built-in";
    }

    // Everything shown here, bound so their volumes and properties are live.
    PwObjectTracker {
        objects: root.nodes
    }

    Section {
        title: "OUTPUT"

        DeviceCard {
            devices: root.outputs
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
            devices: root.inputs
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
                    model: root.apps

                    delegate: Column {
                        id: app

                        required property PwNode modelData
                        readonly property var properties: app.modelData.properties || {}

                        width: appRows.width
                        spacing: Style.widgets.spacing

                        Item {
                            width: parent.width
                            height: Style.text.size + Style.widgets.spacing

                            IconImage {
                                id: appIcon

                                implicitSize: Style.text.size
                                source: Quickshell.iconPath(app.properties["application.icon-name"] || app.properties["application.process.binary"] || "", "audio-x-generic")

                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                text: {
                                    const name = app.properties["application.name"] || app.modelData.description || app.modelData.name;
                                    const media = app.properties["media.name"] || "";
                                    return media !== "" && media !== name ? name + "  ·  " + media : name;
                                }
                                color: Colors.text.base
                                font.family: Style.text.font
                                font.pixelSize: Style.text.smallSize
                                elide: Text.ElideRight

                                anchors {
                                    left: appIcon.right
                                    right: parent.right
                                    leftMargin: Style.widgets.spacing * 2
                                    verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        VolumeRow {
                            width: parent.width
                            node: app.modelData
                        }
                    }
                }

                Text {
                    visible: root.apps.length === 0
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

                delegate: Rectangle {
                    id: device

                    required property PwNode modelData
                    readonly property bool inUse: card.chosen !== null && card.chosen.id === device.modelData.id

                    width: deviceRows.width
                    height: Style.settings.itemHeight
                    radius: Style.popup.rowRadius
                    color: deviceArea.containsMouse && !device.inUse ? Colors.base.hover : "transparent"

                    Icon {
                        id: radio

                        text: device.inUse ? Icons.circleDot : Icons.circle
                        color: device.inUse ? Colors.accent.primary : Colors.text.muted
                        font.pixelSize: Style.text.size

                        anchors {
                            left: parent.left
                            leftMargin: Style.widgets.padding
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        text: root.label(device.modelData)
                        color: device.inUse ? Colors.text.base : Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.size
                        elide: Text.ElideRight

                        anchors {
                            left: radio.right
                            right: kindText.left
                            leftMargin: Style.bar.spacing
                            rightMargin: Style.bar.spacing
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        id: kindText

                        text: root.kind(device.modelData)
                        color: Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.smallSize

                        anchors {
                            right: parent.right
                            rightMargin: Style.widgets.padding
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: deviceArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: device.inUse ? Qt.ArrowCursor : Qt.PointingHandCursor
                        onClicked: {
                            if (!device.inUse)
                                card.picked(device.modelData);
                        }
                    }
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
