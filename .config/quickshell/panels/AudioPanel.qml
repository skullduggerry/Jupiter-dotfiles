import "../style"
import QtQuick
import Quickshell.Services.Pipewire

PanelFrame {
    id: root

    implicitHeight: root.chromeHeight + rows.implicitHeight
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    title: "Audio"

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
            volumeIcon: "\u{F036C}"
            mutedIcon: "\u{F036D}"
        }

        Text {
            width: parent.width
            visible: root.sink !== null
            text: root.sink !== null ? root.sink.description : ""
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            elide: Text.ElideRight
        }
    }
}
