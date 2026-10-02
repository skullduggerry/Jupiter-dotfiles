pragma ComponentBehavior: Bound

import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// SUPER+Tab: every screen shows its workspaces with what is on them. Tab and
// the arrows move the selection through all of them, screen by screen from
// the left; Enter or a click goes there, Escape or a click beside them closes.
// 1 to 9 go to that workspace of the selection's screen, as SUPER+1 to 9 do on
// the focused one, a new one included. SUPER+Tab again goes to the selection,
// as Enter does: Hyprland keeps the bind while this has the keyboard.
Scope {
    id: root

    property bool open: false
    property HyprlandWorkspace selected: null
    // The screen it opened on, whose window takes the keys.
    property ShellScreen keyboardScreen: null
    // Ordinary workspaces in Tab's order: by screen from the left, then as
    // the workspace dropdown lists a screen's (those held for an unplugged
    // monitor last).
    readonly property var workspaces: Hyprland.workspaces.values.filter(workspace => workspace.id > 0 && workspace.monitor !== null).sort((left, right) => left.monitor.x - right.monitor.x || left.monitor.y - right.monitor.y || WorkspaceBlocks.parked(left, left.monitor.name) - WorkspaceBlocks.parked(right, right.monitor.name) || left.id - right.id)

    function show() {
        Hyprland.refreshToplevels();
        root.keyboardScreen = Screens.focused;
        const focused = Hyprland.focusedWorkspace;
        root.selected = root.workspaces.includes(focused) ? focused : root.workspaces[0] ?? null;
        root.open = true;
    }

    function toggle() {
        if (root.open)
            root.go(root.selected);
        else
            root.show();
    }

    function step(by: int) {
        const count = root.workspaces.length;
        if (count === 0)
            return;

        const index = root.workspaces.indexOf(root.selected);
        root.selected = root.workspaces[index < 0 ? 0 : (index + by + count) % count];
    }

    function go(workspace: HyprlandWorkspace) {
        root.open = false;
        workspace?.activate();
    }

    // By id, as config/hypr/modules/workspaces.lua numbers a monitor's. A new
    // workspace comes up on the focused monitor, so that is the selection's
    // first.
    function goNumber(number: int) {
        const monitor = root.selected?.monitor ?? Hyprland.focusedMonitor;
        const block = WorkspaceBlocks.blockOf(monitor?.name ?? "");
        if (block < 0)
            return;

        root.open = false;
        if (monitor !== Hyprland.focusedMonitor)
            Hyprland.dispatch(`hl.dsp.focus({ monitor = ${JSON.stringify(monitor.name)} })`);
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${block * WorkspaceBlocks.idsPerMonitor + number} })`);
    }

    IpcHandler {
        function toggle(): void {
            root.toggle();
        }

        function close(): void {
            root.open = false;
        }

        target: "overview"
    }

    GlobalShortcut {
        name: "overview"
        onPressed: root.toggle()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property ShellScreen modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(window.modelData)
            readonly property var shown: root.workspaces.filter(workspace => workspace.monitor === window.monitor)
            readonly property int columns: Math.max(1, Math.min(window.shown.length, Style.overview.columns))
            readonly property real tileWidth: Math.min(Style.overview.tileWidth, (window.width - Style.overview.margin * 2 - Style.overview.spacing * (window.columns - 1)) / window.columns)

            screen: window.modelData
            visible: root.open
            WlrLayershell.namespace: "quickshell:overview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: window.visible && window.modelData === root.keyboardScreen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            // Over the bars too, as the launcher is.
            exclusionMode: ExclusionMode.Ignore
            color: Colors.overlay.scrim

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

            FocusScope {
                anchors.fill: parent
                focus: true
                Keys.onTabPressed: root.step(1)
                Keys.onBacktabPressed: root.step(-1)
                Keys.onRightPressed: root.step(1)
                Keys.onLeftPressed: root.step(-1)
                Keys.onReturnPressed: root.go(root.selected)
                Keys.onEnterPressed: root.go(root.selected)
                Keys.onSpacePressed: root.go(root.selected)
                Keys.onEscapePressed: root.open = false
                Keys.onPressed: event => {
                    if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9 && (event.modifiers & ~Qt.KeypadModifier) === Qt.NoModifier)
                        root.goNumber(event.key - Qt.Key_0);
                }

                // Built while open, so every window is captured afresh and the
                // tiles come in again each time.
                Loader {
                    id: tiles

                    anchors.centerIn: parent
                    active: root.open

                    sourceComponent: Grid {
                        columns: window.columns
                        spacing: Style.overview.spacing

                        Repeater {
                            model: window.shown

                            delegate: WorkspacePreview {
                                id: preview

                                required property HyprlandWorkspace modelData
                                required property int index

                                width: window.tileWidth
                                zooms: preview.modelData === window.monitor?.activeWorkspace
                                // Outwards from the one on screen.
                                delay: Style.overview.stagger * Math.abs(preview.index - window.shown.indexOf(window.monitor?.activeWorkspace))
                                origin: Qt.point(tiles.x + preview.x, tiles.y + preview.y)
                                workspace: preview.modelData
                                screen: window.modelData
                                selected: root.selected === preview.modelData
                                onHovered: root.selected = preview.modelData
                                onClicked: root.go(preview.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
