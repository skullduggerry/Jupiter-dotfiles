pragma ComponentBehavior: Bound

import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// Caps Lock or SUPER+A: the quick menu, around the pointer over the blurred
// screen. Holding the key, moving toward an item and letting go uses it; a tap
// keeps the menu open for clicks and keys, until Escape, a click beside it or
// the key again. .config/hypr/modules/quickmenu.lua says where the pointer is,
// in custom events ("quickmenu press X Y", "quickmenu release"), as the cursor
// finder's are. SUPER+R opens it as the launcher: in the middle of the
// focused screen, with the apps' list out.
Scope {
    id: root

    property bool open: false
    // Whether it opened with the key held, and where the pointer was then,
    // in the window of the screen it was on.
    property bool held: false
    property point origin: Qt.point(0, 0)
    // Opened by SUPER+R, as the launcher.
    property bool launcher: false
    property ShellScreen screen: Screens.focused

    function show(x: real, y: real, held: bool, launcher: bool) {
        const screen = Screens.at(x, y);
        if (screen === null) {
            console.warn("quick menu: no screen contains", x, y);
            return;
        }
        root.screen = screen;
        root.origin = Qt.point(x - screen.x, y - screen.y);
        root.held = held;
        root.launcher = launcher;
        root.open = true;
    }

    // Open in the middle of the focused screen, or close.
    function toggle(launcher: bool) {
        if (root.open) {
            root.open = false;
            return;
        }
        const screen = Screens.focused;
        if (screen !== null)
            root.show(screen.x + screen.width / 2, screen.y + screen.height / 2, false, launcher);
    }

    QuickMenuItems {
        id: menuItems
    }

    Connections {
        function onRawEvent(event: HyprlandEvent) {
            if (event.name !== "custom" || !event.data.startsWith("quickmenu "))
                return;

            const words = event.data.split(" ");
            const menu = content.item as QuickMenuContent;
            if (words[1] === "release") {
                menu?.release();
            } else if (words[1] === "press") {
                // The key again closes a menu left open.
                if (root.open)
                    root.open = false;
                else
                    root.show(Number(words[2]), Number(words[3]), true, false);
            }
        }

        target: Hyprland
    }

    // SUPER+R.
    GlobalShortcut {
        name: "launcherToggle"
        onPressed: root.toggle(true)
    }

    IpcHandler {
        function toggle(): void {
            root.toggle(false);
        }

        // As the launcher, as SUPER+R does.
        function apps(): void {
            root.toggle(true);
        }

        // At a point of the layout, as the key does but left open.
        function openAt(x: real, y: real): void {
            root.show(x, y, false, false);
        }

        function close(): void {
            root.open = false;
        }

        target: "quickmenu"
    }

    PanelWindow {
        id: window

        visible: root.open
        screen: root.screen
        WlrLayershell.namespace: "quickshell:quickmenu"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: window.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        // Over the bars too.
        exclusionMode: ExclusionMode.Ignore
        color: Colors.base.scrim

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Loader {
            id: content

            anchors.fill: parent
            active: root.open
            focus: true

            sourceComponent: QuickMenuContent {
                items: menuItems
                origin: root.origin
                holding: root.held
                launcher: root.launcher
                onCloseRequested: root.open = false
            }
        }
    }
}
