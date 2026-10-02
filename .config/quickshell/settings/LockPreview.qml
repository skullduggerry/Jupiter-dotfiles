import "../style"
import QtQuick
import QtQuick.Effects
import Quickshell.Widgets

// A lock or login screen in small, as it looks when it comes up: its
// background, LockLook's blur, dim and clock, and the password field.
Column {
    id: root

    property string title: ""
    // The background image, "" for plain.
    property string source: ""

    spacing: Style.bar.spacing

    ClippingRectangle {
        width: root.width
        height: Math.round(root.width * Style.lock.previewRatio)
        radius: Style.wallpaper.cardRadius
        color: Colors.lock.background

        Image {
            id: picture

            anchors.fill: parent
            source: root.source !== "" ? "file://" + root.source : ""
            sourceSize.width: Style.wallpaper.thumbnailWidth
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: picture
            visible: picture.status === Image.Ready
            autoPaddingEnabled: false
            blurEnabled: true
            blurMax: Style.lock.previewBlurMax
            blur: LockLook.blurFor(false)
        }

        Rectangle {
            anchors.fill: parent
            color: Colors.lock.scrim
        }

        Column {
            anchors.centerIn: parent
            spacing: Style.widgets.spacing

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: LockLook.clock
                text: Qt.formatDateTime(new Date(), "HH:mm")
                color: Colors.lock.text
                font.family: Style.text.font
                font.pixelSize: Style.text.largeSize
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Style.lock.previewFieldWidth
                height: Style.lock.previewFieldHeight
                radius: height / 2
                color: Colors.lock.field
                border.width: Style.border.width
                border.color: Colors.lock.fieldBorder
            }
        }
    }

    Text {
        text: root.title
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
    }
}
