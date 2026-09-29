pragma ComponentBehavior: Bound

import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property bool open: false

    IpcHandler {
        function toggle(): void {
            root.open = !root.open;
        }

        function open(): void {
            root.open = true;
        }

        function close(): void {
            root.open = false;
        }

        target: "launcher"
    }

    GlobalShortcut {
        name: "launcherToggle"
        onPressed: root.open = !root.open
    }

    PanelWindow {
        id: window

        visible: root.open
        screen: Screens.focused
        WlrLayershell.namespace: "quickshell:launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: window.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: Colors.base.scrim

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }

        Loader {
            id: content

            anchors.centerIn: parent
            active: root.open
            onLoaded: (content.item as LauncherContent).reset()

            sourceComponent: LauncherContent {
                onLaunched: root.open = false
                onCancelled: root.open = false
            }
        }
    }
}
