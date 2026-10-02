pragma ComponentBehavior: Bound

import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

// A workspace as it looks: its wallpaper and its windows where they are, each
// a frame captured as the overview opened, and its number in a label as the
// wallpaper cards have theirs. It comes in as it is built: from the whole
// screen into its place when it `zooms` (the workspace on screen), else
// popping up after `delay`.
Item {
    id: root

    required property HyprlandWorkspace workspace
    required property ShellScreen screen
    property bool selected: false
    property bool zooms: false
    property int delay: 0
    // Where it sits in its window, which the zoom starts from the corner of.
    property point origin
    // 0 as it comes in (the whole screen, or not there yet), 1 in its place.
    property real reveal: 0
    readonly property real away: 1 - root.reveal
    // Layout units to the preview's.
    readonly property real ratio: picture.width / root.screen.width
    // How much larger than its place the zooming one is drawn.
    readonly property real zoomScale: root.zooms ? 1 + (root.screen.width / root.width - 1) * root.away : 1

    signal hovered
    signal clicked

    implicitHeight: Math.round(root.width * root.screen.height / root.screen.width)
    z: root.zooms ? 1 : 0
    opacity: root.zooms ? 1 : Math.min(1, root.reveal)
    Component.onCompleted: entrance.start()
    transform: [
        Scale {
            readonly property real factor: root.zooms ? root.zoomScale : Style.overview.popFrom + (1 - Style.overview.popFrom) * root.reveal

            origin.x: root.zooms ? 0 : root.width / 2
            origin.y: root.zooms ? 0 : root.height / 2
            xScale: factor
            yScale: factor
        },
        Translate {
            x: root.zooms ? -root.origin.x * root.away : 0
            y: root.zooms ? -root.origin.y * root.away : 0
        }
    ]

    SequentialAnimation {
        id: entrance

        PauseAnimation {
            duration: root.zooms ? 0 : root.delay
        }

        NumberAnimation {
            target: root
            property: "reveal"
            to: 1
            duration: Style.overview.zoom
            easing.type: root.zooms ? Easing.OutCubic : Easing.OutBack
        }
    }

    ClippingRectangle {
        id: picture

        anchors.fill: parent
        // Square at the screen's size, where a corner would show what is behind.
        radius: root.zooms ? Style.bar.radius * root.reveal / root.zoomScale : Style.bar.radius
        color: Colors.base.surface

        Image {
            readonly property string path: WallpaperService.wallpaperFor(root.workspace)

            anchors.fill: parent
            source: path === "" ? "" : "file://" + path
            sourceSize.width: Style.wallpaper.thumbnailWidth
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        Repeater {
            model: root.workspace.toplevels

            // Where Hyprland last reported it (Hyprland.refreshToplevels() on
            // open), floating ones over the tiled.
            delegate: Item {
                id: window

                required property HyprlandToplevel modelData
                readonly property var place: window.modelData.lastIpcObject
                readonly property HyprlandMonitor monitor: root.workspace.monitor

                visible: window.place.at !== undefined && window.monitor !== null
                x: window.visible ? (window.place.at[0] - window.monitor.x) * root.ratio : 0
                y: window.visible ? (window.place.at[1] - window.monitor.y) * root.ratio : 0
                width: window.visible ? window.place.size[0] * root.ratio : 0
                height: window.visible ? window.place.size[1] * root.ratio : 0
                z: window.place.floating ? 1 : 0

                // Until the frame arrives, or for a window that cannot be
                // captured: its outline.
                Rectangle {
                    anchors.fill: parent
                    visible: !capture.hasContent
                    radius: Style.popup.rowRadius
                    color: Colors.base.surface
                    border.width: Style.border.width
                    border.color: Colors.base.border
                }

                ScreencopyView {
                    id: capture

                    anchors.fill: parent
                    captureSource: window.modelData.wayland
                }
            }
        }
    }

    // The frame and the label come with it, rather than drawn across the screen.
    Rectangle {
        anchors.fill: parent
        opacity: Math.min(1, root.reveal)
        radius: Style.bar.radius
        color: "transparent"
        border.width: root.selected ? Style.settings.swatchRing : Style.border.width
        border.color: root.selected ? Colors.accent.primary : Colors.overlay.border
    }

    Rectangle {
        opacity: Math.min(1, root.reveal)
        width: label.implicitWidth + Style.wallpaper.labelPadding * 2
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

            anchors.centerIn: parent
            text: WorkspaceBlocks.number(root.workspace)
            color: Colors.overlay.text
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            font.weight: root.workspace.active ? Font.Medium : Font.Normal
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered()
        onClicked: root.clicked()
    }
}
