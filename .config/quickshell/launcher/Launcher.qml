import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../style"

Scope {
    id: launcherScope

    property bool launcherVisible: false
    readonly property ShellScreen focusedScreen: {
        const monitor = Hyprland.focusedMonitor
        if (monitor === null) return null
        return Quickshell.screens.find(candidate => candidate.name === monitor.name) || null
    }

    function toggle() {
        launcherVisible = !launcherVisible
    }
    IpcHandler {
        target: "launcher"
        function toggle(): void { launcherScope.toggle() }
        function open(): void { launcherScope.launcherVisible = true }
        function close(): void { launcherScope.launcherVisible = false }
    }
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

        MouseArea {
            anchors.fill: parent
            onClicked: launcherScope.launcherVisible = false
        }

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
