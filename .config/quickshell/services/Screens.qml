pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Which screen a surface that follows the user opens on.
Singleton {
    id: root

    // Hyprland's focused monitor, which follows the pointer.
    readonly property ShellScreen focused: {
        const monitor = Hyprland.focusedMonitor;
        return monitor === null ? null : Quickshell.screens.find(screen => screen.name === monitor.name) || null;
    }

    // The screen under a point in layout coordinates, as a gesture reports it.
    function at(x: real, y: real): ShellScreen {
        return Quickshell.screens.find(screen => x >= screen.x && x < screen.x + screen.width && y >= screen.y && y < screen.y + screen.height) || null;
    }
}
