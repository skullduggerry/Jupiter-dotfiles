pragma ComponentBehavior: Bound

import "../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Where the pointer is, when Left Ctrl is tapped twice: every screen dims but
// a circle around the pointer, which closes in on it and then follows it.
// .config/hypr/modules/cursor.lua sees the taps and says where the pointer
// goes, in custom events ("cursorfinder show X Y", "… move X Y", "… hide"),
// so this takes no input at all: clicks and keys go where they always would.
Scope {
    id: root

    property bool shown: false
    // In layout coordinates, as Hyprland has the pointer.
    property point position: Qt.point(0, 0)
    // From the circle at zoomFrom times its size to the circle itself.
    property real reveal: 0
    readonly property real radius: Style.cursorFinder.radius * (Style.cursorFinder.zoomFrom - (Style.cursorFinder.zoomFrom - 1) * root.reveal)

    Connections {
        function onRawEvent(event: HyprlandEvent) {
            // A reload stops Hyprland's side before it could say hide.
            if (event.name === "configreloaded")
                root.shown = false;
            if (event.name !== "custom" || !event.data.startsWith("cursorfinder "))
                return;

            const words = event.data.split(" ");
            if (words[1] === "hide") {
                root.shown = false;
                return;
            }
            root.position = Qt.point(Number(words[2]), Number(words[3]));
            if (words[1] === "show") {
                root.shown = true;
                zoom.restart();
            }
        }

        target: Hyprland
    }

    NumberAnimation {
        id: zoom

        target: root
        property: "reveal"
        from: 0
        to: 1
        duration: Style.cursorFinder.zoom
        easing.type: Easing.OutCubic
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property ShellScreen modelData
            // The pointer in this window, which may be off it, on another screen.
            readonly property point centre: Qt.point(root.position.x - window.modelData.x, root.position.y - window.modelData.y)
            // From the pointer to this window's far corner: a ring that wide
            // covers all of it wherever the pointer is.
            readonly property real reach: Math.hypot(Math.max(window.centre.x, window.width - window.centre.x), Math.max(window.centre.y, window.height - window.centre.y))

            screen: window.modelData
            visible: root.shown || dim.opacity > 0
            color: Colors.base.panel
            WlrLayershell.namespace: "quickshell:cursorfinder"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Item {
                id: dim

                anchors.fill: parent
                opacity: root.shown ? 1 : 0

                // The scrim with the circle cut out of it: the inside of a
                // border reaching past every edge.
                Rectangle {
                    x: window.centre.x - width / 2
                    y: window.centre.y - height / 2
                    width: (root.radius + window.reach) * 2
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: window.reach
                    border.color: Colors.cursorFinder.scrim
                }

                Rectangle {
                    x: window.centre.x - width / 2
                    y: window.centre.y - height / 2
                    width: root.radius * 2
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: Style.cursorFinder.ring
                    border.color: Colors.cursorFinder.ring
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Style.animation.normal
                    }
                }
            }

            // A readout, like the OSD: an empty mask passes every click and
            // scroll to what is underneath, and it never takes the keyboard.
            mask: Region {}
        }
    }
}
