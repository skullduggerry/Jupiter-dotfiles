pragma ComponentBehavior: Bound

import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// SUPER+/: Hyprland's binds over the screen, the Settings app's Keybinds page
// as an overview, with a keyboard in the layout in use. Escape, a click beside
// the panel or the shortcut again closes it.
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

        target: "shortcuts"
    }

    GlobalShortcut {
        name: "shortcutsToggle"
        onPressed: root.open = !root.open
    }

    PanelWindow {
        id: window

        visible: root.open
        screen: Screens.focused
        WlrLayershell.namespace: "quickshell:shortcuts"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: window.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        // Over the bars too, as the launcher is.
        exclusionMode: ExclusionMode.Ignore
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
            anchors.centerIn: parent
            active: root.open

            sourceComponent: ShortcutsContent {
                maximumWidth: window.width - Style.shortcuts.margin * 2
                maximumHeight: window.height - Style.shortcuts.margin * 2
                onCloseRequested: root.open = false
            }
        }
    }
}
