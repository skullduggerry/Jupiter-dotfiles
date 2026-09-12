// bar/widgets/VolumeWidget.qml
import QtQuick
import Quickshell.Services.Pipewire
import "../../style"

Item {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.ready && sink.audio !== null
    readonly property bool muted: ready && sink.audio.muted
    readonly property real volume: ready ? sink.audio.volume : 0

    // Binds the default sink so Pipewire keeps its audio properties
    // populated (and writable) rather than only lazily resolved.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    visible: ready
    implicitWidth: visible ? row.implicitWidth + Style.widgets.padding * 2 : 0
    implicitHeight: Style.bar.height

    readonly property string icon: {
        if (!ready || muted || volume <= 0) return "\uf6a9" // volume-xmark
        if (volume > 0.66) return "\uf028"                  // volume-high
        if (volume > 0.33) return "\uf027"                  // volume-low
        return "\uf026"                                     // volume-off
    }

    function adjust(delta: real) {
        if (!ready) return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + delta))
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Style.widgets.spacing

        Text {
            text: root.icon
            color: root.muted ? Colors.volume.muted : Colors.volume.normal
            font.family: Style.text.font
            font.pixelSize: Style.text.iconSize
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: Math.round(root.volume * 100) + "%"
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.size
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: if (root.ready) root.sink.audio.muted = !root.sink.audio.muted
        onWheel: (wheel) => root.adjust(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
    }
}
