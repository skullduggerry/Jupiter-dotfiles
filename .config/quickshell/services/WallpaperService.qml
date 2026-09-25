pragma Singleton

import Qt.labs.folderlistmodel
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
    // As the app's cards label it: the file name without its extension.
    readonly property string currentName: root.current.split("/").pop().replace(/\.[^.]*$/, "")
    readonly property string defaultConfig: (Quickshell.env("XDG_CONFIG_HOME") || root.home + "/.config") + "/hypr/hyprpaper.conf"
    // modules/start.lua looks for exactly this path.
    readonly property string savedConfig: (Quickshell.env("XDG_STATE_HOME") || root.home + "/.local/state") + "/quickshell/hyprpaper.conf"
    // The wallpaper mode: Static keeps the pick, Rotate moves on through the
    // library in the app's order every rotateMinutes.
    readonly property bool rotating: settings.rotating
    readonly property int rotateMinutes: settings.rotateMinutes
    readonly property var rotateChoices: [5, 15, 30, 60]
    // A singleton is built on first use, and a rotating wallpaper has to turn
    // from login: the wallpaper app's scope, which the shell always builds,
    // sets this.
    property bool active: false
    property string error: ""
    // ~/Wallpapers, watched, so an import shows up by itself. The app's grid
    // shows this model, so rotation walks exactly what the app shows.
    readonly property FolderListModel
    library: FolderListModel {
        folder: "file://" + root.directory
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp"]
        caseSensitive: false
        showDirs: false
        sortCaseSensitive: false
    }

    function rotateLabel(minutes: int) : string {
        return minutes % 60 === 0 ? minutes / 60 + " h" : minutes + " min";
    }

    function setRotating(enabled: bool) {
        settings.rotating = enabled;
        writeDebounce.restart();
    }

    function setRotateMinutes(minutes: int) {
        settings.rotateMinutes = minutes;
        writeDebounce.restart();
    }

    // The wallpaper after the current one, wrapping; the first one when the
    // current wallpaper is not in the library at all.
    function next() {
        const count = root.library.count;
        if (count === 0)
            return ;

        let index = 0;
        for (let candidate = 0; candidate < count; candidate++) {
            if (root.library.get(candidate, "filePath") === root.current) {
                index = (candidate + 1) % count;
                break;
            }
        }
        root.apply(root.library.get(index, "filePath"));
    }

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

    Component.onCompleted: {
        settingsFile.text();
        chosen.path = root.pathIn(savedFile.text()) || root.pathIn(defaultFile.text());
    }

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
            // A wallpaper picked while rotating gets a whole turn of its own.
            if (rotation.running)
                rotation.restart();

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

    Timer {
        id: rotation

        interval: Math.max(1, root.rotateMinutes) * 60000
        repeat: true
        running: root.active && root.rotating && root.library.count > 1
        onTriggered: root.next()
    }

    Timer {
        id: writeDebounce

        interval: 200
        onTriggered: settingsFile.writeAdapter()
    }

    FileView {
        id: settingsFile

        path: Quickshell.statePath("wallpaper.json")
        preload: true
        blockLoading: true
        printErrors: false
        watchChanges: false

        adapter: JsonAdapter {
            id: settings

            property bool rotating: false
            property int rotateMinutes: 15
        }

    }

}
