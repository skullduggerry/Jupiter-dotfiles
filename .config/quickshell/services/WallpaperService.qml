pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The wallpaper the wallpaper app sets through hyprpaper's IPC. The choice is
// kept as a hyprpaper config of its own, which config/hypr/modules/start.lua
// starts hyprpaper from at login; until something is picked, hyprpaper.conf's
// wallpaper is the current one.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string directory: root.home + "/Wallpapers"
    readonly property string current: chosen.path
    readonly property string defaultConfig: (Quickshell.env("XDG_CONFIG_HOME") || root.home + "/.config") + "/hypr/hyprpaper.conf"
    // modules/start.lua looks for exactly this path.
    readonly property string savedConfig: (Quickshell.env("XDG_STATE_HOME") || root.home + "/.local/state") + "/quickshell/hyprpaper.conf"
    property string error: ""

    function apply(path: string) {
        if (setter.running)
            return ;

        root.error = "";
        setter.path = path;
        setter.running = true;
    }

    function importFile() {
        root.error = "";
        importer.added = "";
        importer.running = true;
    }

    // The last `path =` in a hyprpaper config, with `~` expanded as hyprpaper does.
    function pathIn(config: string) : string {
        const pattern = /^\s*path\s*=\s*(.+?)\s*$/gm;
        let path = "";
        let match = pattern.exec(config);
        while (match !== null) {
            path = match[1];
            match = pattern.exec(config);
        }
        return path.startsWith("~") ? root.home + path.slice(1) : path;
    }

    Component.onCompleted: chosen.path = root.pathIn(savedFile.text()) || root.pathIn(defaultFile.text())

    QtObject {
        id: chosen

        property string path: ""
    }

    Process {
        id: setter

        property string path: ""

        // cover, and not hyprpaper.conf's old fill: fill is hyprpaper's
        // stretch, which its IPC cannot express at all.
        command: ["hyprctl", "hyprpaper", "wallpaper", "," + setter.path + ",cover"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.error = "hyprpaper did not take " + setter.path.split("/").pop();
                return ;
            }
            chosen.path = setter.path;
            // Sources hyprpaper.conf first, so its other settings still apply,
            // then overrides its wallpaper: a later block for the same monitor wins.
            savedFile.setText(["# Written by the wallpaper app (config/quickshell/services/WallpaperService.qml).", "source = " + root.defaultConfig, "", "wallpaper {", "    monitor =", "    path = " + setter.path, "    fit_mode = cover", "}", ""].join("\n"));
        }

        stdout: SplitParser {
            onRead: (line) => {
                return console.warn("wallpaper:", line);
            }
        }

    }

    Process {
        id: importer

        property string added: ""

        command: [Quickshell.shellDir + "/services/wallpaper-import.sh", root.directory]
        onExited: (exitCode, exitStatus) => {
            // 1 is the file dialog being cancelled.
            if (exitCode === 0 && importer.added !== "")
                root.apply(importer.added);
            else if (exitCode > 1)
                root.error = "Could not add the wallpaper";
        }

        stdout: SplitParser {
            onRead: (line) => {
                importer.added = line;
            }
        }

    }

    FileView {
        id: savedFile

        path: root.savedConfig
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: defaultFile

        path: root.defaultConfig
        blockLoading: true
        printErrors: false
    }

}
