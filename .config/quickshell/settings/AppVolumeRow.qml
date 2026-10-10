import "../panels"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets

// An app playing sound (the Sound page): its icon and name, with what it
// plays, over its own volume. The node has to be bound (PwObjectTracker) by
// whoever shows it.
Column {
    id: root

    required property PwNode node
    readonly property var properties: root.node.properties || {}

    spacing: Style.widgets.spacing

    Item {
        width: parent.width
        height: Style.text.size + Style.widgets.spacing

        IconImage {
            id: appIcon

            implicitSize: Style.text.size
            source: Quickshell.iconPath(root.properties["application.icon-name"] || root.properties["application.process.binary"] || "", "audio-x-generic")

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
        }

        Text {
            text: {
                const name = root.properties["application.name"] || root.node.description || root.node.name;
                const media = root.properties["media.name"] || "";
                return media !== "" && media !== name ? name + "  ·  " + media : name;
            }
            textFormat: Text.PlainText
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
        node: root.node
    }
}
