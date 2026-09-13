// launcher/Launcher.qml
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../style"

Scope {
    id: launcherScope

    property bool launcherVisible: false

    // The monitor the launcher opens on. Hyprland knows which one the user is
    // looking at; Quickshell.screens is the list a window can actually be
    // assigned to, and the two are matched by output name because
    // HyprlandMonitor carries no ShellScreen of its own.
    //
    // This is what the old "wrap it in Variants" note was after: one window
    // that follows the focus, rather than a launcher on every screen at once
    // (which is what Variants would give) or one pinned to screens[0].
    readonly property ShellScreen focusedScreen: {
        const monitor = Hyprland.focusedMonitor
        if (monitor === null) return null
        return Quickshell.screens.find(candidate => candidate.name === monitor.name) || null
    }

    function toggle() {
        launcherVisible = !launcherVisible
    }

    // Manual/scripted trigger, compositor-independent:
    //   qs -c <config> ipc call launcher toggle/open/close
    // Handy for testing from a terminal regardless of how the keybind fires.
    IpcHandler {
        target: "launcher"
        function toggle(): void { launcherScope.toggle() }
        function open(): void { launcherScope.launcherVisible = true }
        function close(): void { launcherScope.launcherVisible = false }
    }

    // Hyprland-native trigger, no process spawn per press. appid defaults
    // to "quickshell", so this registers as "quickshell:launcherToggle".
    // Bind it with:
    //   bindd = SUPER, R, Toggle launcher, global, quickshell:launcherToggle
    GlobalShortcut {
        name: "launcherToggle"
        onPressed: launcherScope.toggle()
    }

    PanelWindow {
        id: window
        visible: launcherScope.launcherVisible
        screen: launcherScope.focusedScreen

        WlrLayershell.namespace: "quickshell:launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: window.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: Colors.base.scrim

        // click the dimmed backdrop to close
        MouseArea {
            anchors.fill: parent
            onClicked: launcherScope.launcherVisible = false
        }

        // Built only while the launcher is actually open. Creating it eagerly
        // meant every shell start scanned the desktop entries and rendered an
        // icon for each one into a window nobody was looking at (llm.md §15).
        // Each open therefore gets a fresh, already-empty content instance.
        Loader {
            id: content
            anchors.centerIn: parent
            active: launcherScope.launcherVisible
            onLoaded: content.item.reset()

            sourceComponent: LauncherContent {
                onLaunched: launcherScope.launcherVisible = false
                onCancelled: launcherScope.launcherVisible = false
            }
        }
    }
}
