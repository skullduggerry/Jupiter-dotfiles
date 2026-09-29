import "../style"
import QtQuick

// An icon, a slider and its value in percent, as the audio and brightness
// panels show them. The icon can be clicked, to mute for instance.
Row {
    id: root

    property string icon: ""
    property real value: 0

    signal moved(real position)
    signal iconClicked

    spacing: Style.widgets.spacing

    Text {
        width: Style.popup.rowIconWidth
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        color: Colors.icon.active
        font.family: Style.text.font
        font.pixelSize: Style.text.iconSize

        MouseArea {
            anchors.fill: parent
            anchors.margins: -Style.widgets.spacing
            onClicked: root.iconClicked()
        }
    }

    PanelSlider {
        width: root.width - Style.popup.rowIconWidth * 3 - root.spacing * 2
        anchors.verticalCenter: parent.verticalCenter
        value: root.value
        onMoved: position => root.moved(position)
    }

    Text {
        width: Style.popup.rowIconWidth * 2
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.value * 100) + "%"
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
    }
}
