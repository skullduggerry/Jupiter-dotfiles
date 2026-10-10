import "../icons"
import "../style"
import QtQuick
import Quickshell.Services.Pipewire

PanelFrame {
    id: root

    implicitHeight: root.chromeHeight + rows.implicitHeight
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    // Off in the OSD, which takes no clicks.
    property bool showsApplet: true

    title: "Audio"
    trailing: AppletButton {
        visible: root.showsApplet
        command: ["pavucontrol"]
    }

    PwObjectTracker {
        objects: [root.sink, root.source].filter(node => node !== null)
    }

    Column {
        id: rows

        width: parent.width
        spacing: Style.bar.spacing

        VolumeRow {
            width: parent.width
            node: root.sink
        }

        VolumeRow {
            id: sourceRow

            visible: sourceRow.ready
            width: parent.width
            node: root.source
            volumeIcon: Icons.mic
            mutedIcon: Icons.micOff
        }

        Text {
            width: parent.width
            visible: root.sink !== null
            text: root.sink !== null ? root.sink.description : ""
            textFormat: Text.PlainText
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            elide: Text.ElideRight
        }
    }
}
