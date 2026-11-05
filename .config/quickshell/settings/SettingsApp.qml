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

    // The tablet's pad keys work whether or not the window is open.
    Binding {
        target: Tablet
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

    // Hyprland's blur, and the glass colours it takes from the theme, follow
    // the Settings app's choices whether or not the window is open.
    Binding {
        target: HyprBlur
        property: "active"
        value: true
    }

    Binding {
        target: HyprBlur
        property: "variant"
        value: Colors.base.variant.value
    }

    Binding {
        target: HyprBlur
        property: "size"
        value: Theme.blurSize
    }

    Binding {
        target: HyprBlur
        property: "options"
        value: BlurVariants.effective(Theme.blurOptions)
    }

    Binding {
        target: HyprBlur
        property: "colors"
        value: ({
                "acrylic.tint": Colors.hyprland(Colors.base.glassTint),
                "aurora.color1": Colors.hyprland(Colors.base.glowFirst),
                "aurora.color2": Colors.hyprland(Colors.base.glowSecond),
                "fluid_jar.color": Colors.hyprland(Colors.base.fluid)
            })
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
        // keyboard (and keybinds, mouse), tablet, about (and startup).
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
            // Quickshell picks the surface's alpha channel once, from the
            // colour the window is created with: opened over Solid, it would
            // stay opaque, and glass (Blur, or a theme over it) would show only
            // once the window was opened again.
            surfaceFormat.opaque: false
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
