import "../services"
import "../style"
import QtQuick
import Quickshell.Widgets

// A wallpaper as the design draws it: the picture, its name in a pill, and the
// ring and check of the one applied.
Item {
    id: root

    required property string filePath
    required property url fileUrl
    required property string fileBaseName
    readonly property bool applied: WallpaperService.current === root.filePath

    signal clicked

    ClippingRectangle {
        anchors.fill: parent
        radius: Style.wallpaper.cardRadius
        color: Colors.base.hover

        Image {
            anchors.fill: parent
            source: root.fileUrl
            // Fixed rather than the card's size, which follows the window: a
            // binding to it would decode every image again on each resize step.
            sourceSize.width: Style.wallpaper.thumbnailWidth
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        Rectangle {
            anchors.fill: parent
            color: area.containsMouse ? Colors.base.hover : "transparent"
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Style.wallpaper.cardRadius
        color: "transparent"
        border.color: Colors.overlay.text
        border.width: Style.border.width * 2
        visible: root.applied
    }

    Rectangle {
        width: Style.wallpaper.badgeSize
        height: Style.wallpaper.badgeSize
        radius: width / 2
        color: Colors.overlay.text
        visible: root.applied

        anchors {
            top: parent.top
            right: parent.right
            margins: Style.wallpaper.badgeInset
        }

        Text {
            anchors.centerIn: parent
            text: "\u{F012C}"
            color: Colors.overlay.inverted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
        }
    }

    Rectangle {
        visible: root.fileBaseName !== ""
        width: Math.min(label.implicitWidth + Style.wallpaper.labelPadding * 2, root.width - Style.wallpaper.badgeInset * 2)
        height: Style.wallpaper.labelHeight
        radius: Style.wallpaper.labelRadius
        color: Colors.overlay.scrim

        anchors {
            left: parent.left
            bottom: parent.bottom
            margins: Style.wallpaper.badgeInset
        }

        Text {
            id: label

            anchors.fill: parent
            anchors.leftMargin: Style.wallpaper.labelPadding
            anchors.rightMargin: Style.wallpaper.labelPadding
            text: root.fileBaseName
            color: Colors.overlay.text
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
