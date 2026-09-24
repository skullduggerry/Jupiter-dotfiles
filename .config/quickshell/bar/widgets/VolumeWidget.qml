import "../../style"
import QtQuick
import Quickshell.Services.Pipewire

Item {
    id: root

    required property QuickPager pager
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.ready && sink.audio !== null
    readonly property bool muted: ready && sink.audio.muted
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property string icon: {
        if (!ready || muted || volume <= 0)
            return "󰝟";

        if (volume > 0.66)
            return "󰕾";

        if (volume > 0.33)
            return "󰖀";

        return "󰕿";
    }

    function adjust(delta: real) {
        if (!ready)
            return ;

        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + delta));
    }

    visible: ready
    implicitWidth: visible ? row.implicitWidth + Style.widgets.padding * 2 : 0
    implicitHeight: Style.bar.height

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Style.widgets.spacing

        Text {
            text: root.icon
            color: Colors.icon.active
            font.family: Style.text.font
            font.pixelSize: Style.text.iconSize
            anchors.verticalCenter: parent.verticalCenter
        }

    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                if (root.ready)
                    root.sink.audio.muted = !root.sink.audio.muted;

            } else {
                root.pager.toggleAt(root.pager.pageAudio, root);
            }
        }
        onWheel: (wheel) => {
            return root.adjust(wheel.angleDelta.y > 0 ? 0.05 : -0.05);
        }
    }

}
