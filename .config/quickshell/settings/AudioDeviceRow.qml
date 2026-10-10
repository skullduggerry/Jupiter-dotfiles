import "../icons"
import "../services"
import "../style"
import QtQuick
import Quickshell.Services.Pipewire

// An output or input to pick (the Sound page): a radio, its name and what
// kind of device it is.
Rectangle {
    id: root

    required property PwNode node
    property bool inUse: false

    signal picked

    height: Style.settings.itemHeight
    radius: Style.popup.rowRadius
    color: area.containsMouse && !root.inUse ? Colors.base.hover : "transparent"

    Icon {
        id: radio

        text: root.inUse ? Icons.circleDot : Icons.circle
        color: root.inUse ? Colors.accent.primary : Colors.text.muted
        font.pixelSize: Style.text.size

        anchors {
            left: parent.left
            leftMargin: Style.widgets.padding
            verticalCenter: parent.verticalCenter
        }
    }

    Text {
        text: Volume.label(root.node)
        textFormat: Text.PlainText
        color: root.inUse ? Colors.text.base : Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.size
        elide: Text.ElideRight

        anchors {
            left: radio.right
            right: kind.left
            leftMargin: Style.bar.spacing
            rightMargin: Style.bar.spacing
            verticalCenter: parent.verticalCenter
        }
    }

    Text {
        id: kind

        text: Volume.kind(root.node)
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
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.inUse ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: {
            if (!root.inUse)
                root.picked();
        }
    }
}
