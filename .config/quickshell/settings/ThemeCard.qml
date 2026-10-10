import "../icons"
import "../style"
import QtQuick

// A theme drawn in its own colours, the way the shell will look in it.
Rectangle {
    id: root

    // One entry of .config/wallust/palettes.py's output.
    required property var modelData
    readonly property var colours: root.modelData.palette
    readonly property bool applied: Theme.theme === root.modelData.name

    radius: Style.wallpaper.cardRadius
    color: root.colours.background
    // Marked in the card's own foreground, the one colour sure to stand off
    // its background whatever the shell's theme is.
    border.color: root.applied ? root.colours.foreground : Colors.base.border
    border.width: root.applied ? Style.border.width * 2 : Style.border.width

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: area.containsMouse ? Colors.base.hover : "transparent"
    }

    Text {
        text: root.modelData.name
        textFormat: Text.PlainText
        color: root.colours.foreground
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
        elide: Text.ElideRight

        anchors {
            left: parent.left
            right: badge.left
            top: parent.top
            margins: Style.wallpaper.badgeInset
        }
    }

    Rectangle {
        id: badge

        width: Style.wallpaper.badgeSize
        height: Style.wallpaper.badgeSize
        radius: width / 2
        color: root.colours.foreground
        visible: root.applied

        anchors {
            top: parent.top
            right: parent.right
            margins: Style.wallpaper.badgeInset
        }

        Icon {
            anchors.centerIn: parent
            text: Icons.check
            color: root.colours.background
            font.pixelSize: Style.text.smallSize
        }
    }

    Row {
        spacing: Style.widgets.spacing

        anchors {
            left: parent.left
            bottom: parent.bottom
            margins: Style.wallpaper.badgeInset
        }

        Repeater {
            model: [root.colours.color1, root.colours.color2, root.colours.color3, root.colours.color4, root.colours.color5, root.colours.color6]

            Rectangle {
                id: swatch

                required property string modelData

                width: Style.wallpaper.swatchSize
                height: Style.wallpaper.swatchSize
                radius: width / 2
                color: swatch.modelData
            }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Theme.apply(root.modelData.name)
    }
}
