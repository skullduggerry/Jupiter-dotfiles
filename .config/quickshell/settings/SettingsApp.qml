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

    // Kitty, the Qt apps and the GTK apps follow the glass while themes apply
    // to apps.
    Binding {
        target: AppTint
        property: "active"
        value: Theme.applyToApps
    }

    Binding {
        target: AppTint
        property: "opacity"
        value: Colors.base.opacity
    }

    IpcHandler {
        function toggle(): void {
            SettingsState.toggle("");
        }

        function open(): void {
            SettingsState.show("");
        }

        // By name: appearance (and its tabs wallpaper, themes and lockscreen),
        // displays, sound, network (and bluetooth), notifications, power,
        // keyboard (and keybinds), about (and startup).
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
