// launcher/Launcher.qml
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: launcherScope

    property bool launcherVisible: false

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

    // TODO: wrap this in Variants { model: Quickshell.screens }, same as
    // Bar.qml, once you want it to follow the focused monitor instead of
    // just the default one.
    PanelWindow {
        id: window
        visible: launcherScope.launcherVisible

        WlrLayershell.namespace: "quickshell:launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: window.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: Qt.rgba(0, 0, 0, 0.35)

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
