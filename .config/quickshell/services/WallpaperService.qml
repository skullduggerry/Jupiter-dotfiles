pragma Singleton
pragma ComponentBehavior: Bound

import Qt.labs.folderlistmodel
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// The wallpaper, set through hyprpaper's IPC. The one for every workspace is
// kept as a hyprpaper config of its own, which hyprpaper starts from at login
// (config/hypr/modules/startup.lua); until something is picked, it is
// hyprpaper.conf's. A workspace can have one of its own on top, which its
// monitor shows while the workspace is on it.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string directory: root.home + "/Wallpapers"
    readonly property list<string> imageFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp"]
    // The one for every workspace without its own.
    readonly property string allWorkspaces: chosen.path
    // What the focused monitor shows.
    readonly property string current: root.wallpaperFor(Hyprland.focusedMonitor ? Hyprland.focusedMonitor.activeWorkspace : null)
    // As the cards label it: the file name without its extension.
    readonly property string currentName: root.current.split("/").pop().replace(/\.[^.]*$/, "")
    readonly property string defaultConfig: (Quickshell.env("XDG_CONFIG_HOME") || root.home + "/.config") + "/hypr/hyprpaper.conf"
    // modules/start.lua looks for exactly this path.
    readonly property string savedConfig: (Quickshell.env("XDG_STATE_HOME") || root.home + "/.local/state") + "/quickshell/hyprpaper.conf"
    // Static keeps the pick, Rotate moves on through the library, in the
    // grid's order, every rotateMinutes.
    readonly property bool rotating: settings.rotating
    readonly property var modeChoices: [
        {
            label: "Static",
            value: false
        },
        {
            label: "Rotate",
            value: true
        }
    ]
    readonly property int rotateMinutes: settings.rotateMinutes
    readonly property list<int> rotateChoices: [5, 15, 30, 60]
    // Where a pick goes: "all" workspaces, or the focused "workspace" alone.
    readonly property string target: settings.target
    // The category tab: a subfolder of ~/Wallpapers, or "" for all of them.
    readonly property string category: settings.category
    readonly property var categoryNames: {
        const names = [];
        for (let index = 0; index < categoryFolders.count; index++)
            names.push(categoryFolders.get(index, "fileName"));
        return names;
    }
    // Set from login by the Settings app's scope, which the shell always
    // builds: a singleton is only built on first use.
    property bool active: false
    property string error: ""
    // The tab's wallpapers, by name: what the grid shows and rotation walks.
    readonly property ListModel library: ListModel {}
    // monitor name -> the path hyprpaper was last told to show there by name
    property var shown: ({})
    // {monitor, path}, sent one at a time; monitor "" is the fallback
    property var queue: []

    function rotateLabel(minutes: int): string {
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

    function setTarget(value: string) {
        settings.target = value;
        writeDebounce.restart();
    }

    function setCategory(name: string) {
        settings.category = name;
        writeDebounce.restart();
    }

    function wallpaperFor(workspace: HyprlandWorkspace): string {
        return settings.workspaces[WorkspaceBlocks.key(workspace)] || chosen.path;
    }

    // Tells hyprpaper what each monitor should now show, where that is not what
    // it was told already. Once named, hyprpaper keeps a monitor off the
    // fallback, and hyprpaper outlives the shell: a monitor this shell has not
    // named may be on an earlier one's pick, so it is named too, once.
    function sync() {
        const pending = root.queue.filter(job => job.monitor === "");
        for (const monitor of Hyprland.monitors.values) {
            const path = root.wallpaperFor(monitor.activeWorkspace);
            if (path !== "" && root.shown[monitor.name] !== path)
                pending.push({
                    monitor: monitor.name,
                    path: path
                });
        }
        root.queue = pending;
        root.next();
    }

    function next() {
        if (setter.running || root.queue.length === 0)
            return;

        const job = root.queue[0];
        root.queue = root.queue.slice(1);
        setter.monitor = job.monitor;
        setter.path = job.path;
        setter.running = true;
    }

    // The wallpaper after the one for every workspace, wrapping; the first one
    // when it is not in the library at all.
    function rotate() {
        const count = root.library.count;
        if (count === 0)
            return;

        let index = 0;
        for (let candidate = 0; candidate < count; candidate++) {
            if (root.library.get(candidate).filePath === chosen.path) {
                index = (candidate + 1) % count;
                break;
            }
        }
        root.setAllWorkspaces(root.library.get(index).filePath, false);
    }

    // A pick, wherever target says.
    function apply(path: string) {
        root.error = "";
        const key = WorkspaceBlocks.key(Hyprland.focusedWorkspace);
        if (settings.target === "workspace" && key !== "") {
            const own = Object.assign({}, settings.workspaces);
            own[key] = path;
            settings.workspaces = own;
            writeDebounce.restart();
            root.sync();
        } else {
            // All workspaces means all: a workspace's own goes too.
            root.setAllWorkspaces(path, true);
        }
        // A wallpaper picked while rotating gets a whole turn of its own.
        if (rotation.running)
            rotation.restart();
    }

    function setAllWorkspaces(path: string, clearOwn: bool) {
        chosen.path = path;
        // The fallback first, which covers every monitor not yet named and any
        // that turns up later; counted as done, so sync() adds no name for it.
        root.queue = root.queue.concat([
            {
                monitor: "",
                path: path
            }
        ]);
        if (clearOwn && Object.keys(settings.workspaces).length > 0) {
            settings.workspaces = ({});
            writeDebounce.restart();
        }
        // Sources hyprpaper.conf first, so its other settings still apply,
        // then overrides its wallpaper: a later block for the same monitor wins.
        savedFile.setText(["# Written by the shell (config/quickshell/services/WallpaperService.qml).", "source = " + root.defaultConfig, "", "wallpaper {", "    monitor =", "    path = " + path, "    fit_mode = cover", "}", ""].join("\n"));
        root.sync();
    }

    function importFile() {
        root.error = "";
        importer.added = "";
        importer.running = true;
    }

    // The last `path =` in a hyprpaper config, with `~` expanded as hyprpaper does.
    function pathIn(config: string): string {
        const pattern = /^\s*path\s*=\s*(.+?)\s*$/gm;
        let path = "";
        let match = pattern.exec(config);
        while (match !== null) {
            path = match[1];
            match = pattern.exec(config);
        }
        return path.startsWith("~") ? root.home + path.slice(1) : path;
    }

    // Every wallpaper of the tab, by file name. Rebuilt rather than bound: the
    // folders are separate models, and "all" is the top folder and every
    // subfolder together.
    function rebuild() {
        const sources = [];
        if (settings.category === "")
            sources.push(topFolder);

        for (let index = 0; index < subfolders.count; index++) {
            if (settings.category === "" || root.categoryNames[index] === settings.category)
                sources.push(subfolders.objectAt(index));
        }
        const entries = [];
        for (const source of sources) {
            for (let row = 0; row < source.count; row++)
                entries.push({
                    filePath: source.get(row, "filePath"),
                    fileUrl: String(source.get(row, "fileUrl")),
                    fileBaseName: source.get(row, "fileBaseName")
                });
        }
        entries.sort((left, right) => left.fileBaseName.localeCompare(right.fileBaseName, undefined, {
                sensitivity: "base"
            }));
        root.library.clear();
        for (const entry of entries)
            root.library.append(entry);
    }

    Component.onCompleted: {
        settingsFile.text();
        chosen.path = root.pathIn(savedFile.text()) || root.pathIn(defaultFile.text());
        root.sync();
    }
    onCategoryChanged: rebuildDebounce.restart()
    // A category removed while it was the tab leaves "all".
    onCategoryNamesChanged: {
        if (settings.category !== "" && categoryFolders.status === FolderListModel.Ready && root.categoryNames.indexOf(settings.category) === -1)
            root.setCategory("");
    }

    QtObject {
        id: chosen

        property string path: ""
    }

    // The top folder's own wallpapers, then one model per subfolder; all of
    // them watch their directory, so an import or a new folder shows up by itself.
    FolderListModel {
        id: topFolder

        folder: "file://" + root.directory
        nameFilters: root.imageFilters
        caseSensitive: false
        showDirs: false
        onCountChanged: rebuildDebounce.restart()
        onStatusChanged: rebuildDebounce.restart()
    }

    FolderListModel {
        id: categoryFolders

        folder: "file://" + root.directory
        showFiles: false
        showDotAndDotDot: false
        sortCaseSensitive: false
    }

    Instantiator {
        id: subfolders

        model: root.categoryNames
        onObjectAdded: rebuildDebounce.restart()
        onObjectRemoved: rebuildDebounce.restart()

        delegate: FolderListModel {
            required property string modelData

            folder: "file://" + root.directory + "/" + modelData
            nameFilters: root.imageFilters
            caseSensitive: false
            showDirs: false
            onCountChanged: rebuildDebounce.restart()
            onStatusChanged: rebuildDebounce.restart()
        }
    }

    // Folder models settle one after the other; rebuild once they have.
    Timer {
        id: rebuildDebounce

        interval: 50
        onTriggered: root.rebuild()
    }

    // Workspaces change under the monitors, and monitors come and go.
    Instantiator {
        model: Hyprland.monitors
        onObjectAdded: root.sync()

        delegate: Connections {
            required property HyprlandMonitor modelData

            function onActiveWorkspaceChanged() {
                root.sync();
            }

            target: modelData
        }
    }

    Process {
        id: setter

        property string monitor: ""
        property string path: ""

        // cover, and not hyprpaper.conf's old fill: fill is hyprpaper's
        // stretch, which its IPC cannot express at all.
        command: ["hyprctl", "hyprpaper", "wallpaper", setter.monitor + "," + setter.path + ",cover"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.error = "hyprpaper did not take " + setter.path.split("/").pop();
            } else if (setter.monitor !== "") {
                const shown = Object.assign({}, root.shown);
                shown[setter.monitor] = setter.path;
                root.shown = shown;
            }
            root.next();
        }

        stdout: SplitParser {
            onRead: line => console.warn("wallpaper:", line)
        }
    }

    Process {
        id: importer

        property string added: ""

        // Into the tab's folder, so an import lands where it is being looked for.
        command: [Quickshell.shellDir + "/services/wallpaper-import.sh", root.directory + (settings.category === "" ? "" : "/" + settings.category)]
        onExited: (exitCode, exitStatus) => {
            // 1 is the file dialog being cancelled.
            if (exitCode === 0 && importer.added !== "")
                root.apply(importer.added);
            else if (exitCode > 1)
                root.error = "Could not add the wallpaper";
        }

        stdout: SplitParser {
            onRead: line => {
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
        onTriggered: root.rotate()
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
            property string target: "all"
            property string category: ""
            // "DP-2:3" -> path, for the workspaces with a wallpaper of their own
            property var workspaces: ({})
        }
    }
}
