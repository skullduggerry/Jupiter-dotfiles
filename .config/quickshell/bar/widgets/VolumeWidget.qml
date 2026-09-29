import "../../services"
import "../../style"
import QtQuick

Item {
    id: root

    required property QuickPager pager
    readonly property list<string> ramp: ["\u{F057F}", "\u{F0580}", "\u{F057E}"]
    readonly property string glyph: Volume.muted || Volume.volume <= 0 ? "\u{F075F}" : root.ramp[Math.min(root.ramp.length - 1, Math.floor(Volume.volume * root.ramp.length))]

    visible: Volume.ready
    implicitWidth: visible ? icon.implicitWidth + Style.widgets.padding * 2 : 0
    implicitHeight: Style.bar.height

    Text {
        id: icon

        anchors.centerIn: parent
        text: root.glyph
        color: Colors.icon.active
        font.family: Style.text.font
        font.pixelSize: Style.text.iconSize
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
