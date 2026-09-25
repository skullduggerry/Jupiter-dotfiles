import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// The wallpaper app: an ordinary window, tiled like any other, built only
// while it is open so its thumbnails are freed when it closes.
Scope {
    id: root

    property bool open: false

    // A rotating wallpaper turns whether or not the window is open.
    Binding {
        target: WallpaperService
        property: "active"
        value: true
    }

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

        target: "wallpaper"
    }

    GlobalShortcut {
        name: "wallpaperToggle"
        onPressed: root.open = !root.open
    }

    LazyLoader {
        active: root.open

        FloatingWindow {
            title: "Wallpaper"
            implicitWidth: Style.wallpaper.windowWidth
            implicitHeight: Style.wallpaper.windowHeight
            minimumSize: Qt.size(Style.wallpaper.minimumWidth, Style.wallpaper.minimumHeight)
            color: Colors.base.surface
            visible: true
            // Closed by the compositor (SUPER+C), not by us.
            onClosed: root.open = false

            WallpaperContent {
                anchors.fill: parent
                onCloseRequested: root.open = false
            }

        }

    }

}
