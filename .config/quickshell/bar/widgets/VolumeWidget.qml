import "../../icons"
import "../../services"
import "../../style"
import QtQuick

Item {
    id: root

    required property QuickPager pager
    readonly property list<string> ramp: [Icons.volume, Icons.volume1, Icons.volume2]
    readonly property string glyph: Volume.muted || Volume.volume <= 0 ? Icons.volumeX : root.ramp[Math.min(root.ramp.length - 1, Math.floor(Volume.volume * root.ramp.length))]

    visible: Volume.ready
    implicitWidth: visible ? icon.implicitWidth + Style.widgets.padding * 2 : 0
    implicitHeight: Style.bar.height

    Icon {
        id: icon

        anchors.centerIn: parent
        text: root.glyph
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Volume.toggleMute();
            else
                root.pager.toggleAt(root.pager.pageAudio, root);
        }
        onWheel: wheel => Volume.adjust(wheel.angleDelta.y > 0 ? Volume.step : -Volume.step)
    }
}
