pragma Singleton

import QtQuick
import Quickshell

// The apps' glass at the shell's: kitty's background and the Qt apps' window
// and dialog backgrounds (Kvantum's) at Colors.base.opacity, which the
// Settings app hands in while themes apply to apps. With themes on the shell
// alone, the apps are left as they were, the way their colours are.
// app-tint.sh does the writing and the sending.
Singleton {
    id: root

    property bool active: false
    property real opacity: 1

    onActiveChanged: send.restart()
    onOpacityChanged: send.restart()

    // At most one run per moment while the slider is dragged, or while
    // Adaptive settles on a new wallpaper.
    Timer {
        id: send

        interval: 150
        onTriggered: {
            if (root.active)
                Quickshell.execDetached([Quickshell.shellDir + "/services/app-tint.sh", root.opacity.toFixed(2)]);
        }
    }
}
