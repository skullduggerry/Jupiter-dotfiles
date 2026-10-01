import "../../panels"
import "../../services"
import "../../style"
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// What is playing (Media.active): its controls, then the title and, when both
// fit, the artist, which open the player in a dropdown.
Item {
    id: root

    required property ShellScreen screen
    required property real maximumWidth
    readonly property MprisPlayer player: Media.active
    readonly property real trackWidth: Math.max(0, Math.min(Style.media.trackWidth, root.maximumWidth - Style.widgets.padding * 2 - controls.implicitWidth - Style.bar.spacing))

    visible: root.player !== null
    implicitWidth: visible ? controls.implicitWidth + Style.bar.spacing + track.implicitWidth + Style.widgets.padding * 2 : 0
    implicitHeight: Style.bar.height
    // The last player went away with its dropdown open.
    onVisibleChanged: {
        if (!root.visible)
            mediaPopup.visible = false;
    }

    MediaControls {
        id: controls

        spacing: Style.widgets.spacing

        anchors {
            left: parent.left
            leftMargin: Style.widgets.padding
            verticalCenter: parent.verticalCenter
        }
    }

    Row {
        id: track

        spacing: Style.widgets.spacing

        anchors {
            left: controls.right
            leftMargin: Style.bar.spacing
            verticalCenter: parent.verticalCenter
        }

        Text {
            id: title

            width: Math.min(implicitWidth, root.trackWidth)
            text: root.player?.trackTitle ?? ""
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.size
            elide: Text.ElideRight
        }

        Text {
            visible: root.player !== null && root.player.trackArtist !== "" && title.implicitWidth + track.spacing + implicitWidth <= root.trackWidth
            text: "· " + (root.player?.trackArtist ?? "")
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }
    }

    MouseArea {
        onClicked: mediaPopup.visible = !mediaPopup.visible

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: track.left
            right: parent.right
        }
    }

    WidgetPopup {
        id: mediaPopup

        screen: root.screen
        anchorItem: root
        namespaceSuffix: "media-popup"
        popupWidth: Style.dropdown.width
        popupHeight: Math.max(Style.popup.minHeight, Math.min(Style.dropdown.maxHeight, panel.implicitHeight))

        Loader {
            id: panel

            anchors.fill: parent
            active: mediaPopup.visible

            sourceComponent: MediaPanel {}
        }
    }
}
