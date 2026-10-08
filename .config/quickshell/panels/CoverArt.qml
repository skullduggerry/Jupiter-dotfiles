import "../icons"
import "../style"
import QtQuick
import Quickshell.Widgets

// A track's cover, or a note while it has none.
ClippingRectangle {
    id: root

    property string source: ""

    radius: Style.media.artRadius
    color: Colors.base.hover

    Icon {
        anchors.centerIn: parent
        visible: cover.status !== Image.Ready
        text: Icons.music
    }

    Image {
        id: cover

        anchors.fill: parent
        source: root.source
        sourceSize.width: root.width
        sourceSize.height: root.height
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
}
