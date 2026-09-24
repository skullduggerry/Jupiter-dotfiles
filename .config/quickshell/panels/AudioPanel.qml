import "../style"
import QtQuick
import Quickshell.Services.Pipewire

Item {
    id: root

    readonly property int preferredHeight: Style.bar.padding * 2 + header.height + Style.border.width + Style.bar.spacing + rows.implicitHeight
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool sinkReady: root.sink !== null && root.sink.ready && root.sink.audio !== null
    readonly property bool sourceReady: root.source !== null && root.source.ready && root.source.audio !== null

    function setSinkVolume(position: real) {
        if (!root.sinkReady)
            return ;

        root.sink.audio.muted = false;
        root.sink.audio.volume = position;
    }

    function setSourceVolume(position: real) {
        if (!root.sourceReady)
            return ;

        root.source.audio.muted = false;
        root.source.audio.volume = position;
    }

    PwObjectTracker {
        objects: {
            const tracked = [];
            if (root.sink !== null)
                tracked.push(root.sink);

            if (root.source !== null)
                tracked.push(root.source);

            return tracked;
        }
    }

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
                text: "Audio"
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

        Column {
            id: rows

            spacing: Style.bar.spacing

            anchors {
                top: separator.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.bar.spacing
            }

            Row {
                width: parent.width
                spacing: Style.widgets.spacing

                Text {
                    width: Style.popup.rowIconWidth
                    text: root.sinkReady && root.sink.audio.muted ? "󰝟" : "󰕾"
                    color: Colors.icon.active
                    font.family: Style.text.font
                    font.pixelSize: Style.text.iconSize
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.sinkReady)
                                root.sink.audio.muted = !root.sink.audio.muted;

                        }
                    }

                }

                PanelSlider {
                    width: parent.width - Style.popup.rowIconWidth - sinkValue.width - Style.widgets.spacing * 2
                    anchors.verticalCenter: parent.verticalCenter
                    value: root.sinkReady ? root.sink.audio.volume : 0
                    onMoved: (position) => {
                        return root.setSinkVolume(position);
                    }
                }

                Text {
                    id: sinkValue

                    width: Style.popup.rowIconWidth * 2
                    horizontalAlignment: Text.AlignRight
                    text: Math.round((root.sinkReady ? root.sink.audio.volume : 0) * 100) + "%"
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                    anchors.verticalCenter: parent.verticalCenter
                }

            }

            Row {
                width: parent.width
                spacing: Style.widgets.spacing
                visible: root.sourceReady

                Text {
                    width: Style.popup.rowIconWidth
                    text: root.sourceReady && root.source.audio.muted ? "󰍭" : "󰍬"
                    color: Colors.icon.active
                    font.family: Style.text.font
                    font.pixelSize: Style.text.iconSize
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.sourceReady)
                                root.source.audio.muted = !root.source.audio.muted;

                        }
                    }

                }

                PanelSlider {
                    width: parent.width - Style.popup.rowIconWidth - sourceValue.width - Style.widgets.spacing * 2
                    anchors.verticalCenter: parent.verticalCenter
                    value: root.sourceReady ? root.source.audio.volume : 0
                    onMoved: (position) => {
                        return root.setSourceVolume(position);
                    }
                }

                Text {
                    id: sourceValue

                    width: Style.popup.rowIconWidth * 2
                    horizontalAlignment: Text.AlignRight
                    text: Math.round((root.sourceReady ? root.source.audio.volume : 0) * 100) + "%"
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                    anchors.verticalCenter: parent.verticalCenter
                }

            }

            Text {
                width: parent.width
                visible: root.sinkReady
                text: root.sinkReady ? root.sink.description : ""
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
                elide: Text.ElideRight
            }

        }

    }

}
