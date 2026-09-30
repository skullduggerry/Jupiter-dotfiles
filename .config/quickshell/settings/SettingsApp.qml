import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// The Settings app: an ordinary window, built only while it is open.
Scope {
    // A rotating wallpaper turns whether or not the window is open.
    Binding {
        target: WallpaperService
        property: "active"
        value: true
    }

    IpcHandler {
        function toggle(): void {
            SettingsState.toggle("");
        }

        function open(): void {
            SettingsState.show("");
        }

        // By name: appearance (and its wallpaper and themes tabs), displays,
        // sound, network, bluetooth, notifications, power, keybinds, startup,
        // about.
        function openPage(page: string): void {
            SettingsState.show(page);
        }

        function close(): void {
            SettingsState.open = false;
        }

        target: "settings"
    }

    GlobalShortcut {
        name: "settingsToggle"
        onPressed: SettingsState.toggle("")
    }

    GlobalShortcut {
        name: "wallpaperToggle"
        onPressed: SettingsState.toggle("wallpaper")
    }

    LazyLoader {
        active: SettingsState.open

        FloatingWindow {
            title: "Settings"
            implicitWidth: Style.settings.windowWidth
            implicitHeight: Style.settings.windowHeight
            minimumSize: Qt.size(Style.settings.minimumWidth, Style.settings.minimumHeight)
            color: Colors.base.surface
            visible: true
            // Closed by the compositor (SUPER+C), not by us.
            onClosed: SettingsState.open = false

            SettingsContent {
                anchors.fill: parent
                onCloseRequested: SettingsState.open = false
            }
        }
    }
}
