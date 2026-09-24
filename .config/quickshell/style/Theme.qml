pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The palette every colour in Colors.qml derives from, and what changes it:
// config/wallust/apply.sh renders the palette (templates/quickshell.json) and
// records which theme it applied; see .github/THEMING.md. Nothing here runs
// until a theme is picked, because the greeter gets a copy of style/
// (scripts/install-greeter.sh) and must only ever read.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string scripts: (Quickshell.env("XDG_CONFIG_HOME") || root.home + "/.config") + "/wallust"
    readonly property string stateDir: Quickshell.env("XDG_STATE_HOME") || root.home + "/.local/state"
    // The first line of apply.sh's record; its own default before it ran.
    readonly property string theme: applied.text().split("\n")[0] || "Oxocarbon-Dark"
    readonly property bool blur: settings.blur
    readonly property bool applyToApps: settings.applyToApps
    readonly property bool applying: wallust.running
    // Empty strings until wallust has rendered a palette, which Colors reads
    // as "use the shell's own colour".
    readonly property alias palette: paletteData
    property string error: ""
    property string requested: ""
    property string pendingName: ""
    property string pendingImage: ""

    // Applies the theme called name; with an image, generates it from that first.
    function run(name: string, image: string) {
        root.error = "";
        if (wallust.running) {
            root.pendingName = name;
            root.pendingImage = image;
            return ;
        }
        const command = [root.scripts + "/apply.sh"];
        if (!settings.applyToApps)
            command.push("--shell-only");

        if (image === "")
            command.push(name);
        else
            command.push("--from", image);
        root.requested = name;
        wallust.command = command;
        wallust.running = true;
    }

    function runPending() {
        const name = root.pendingName;
        root.pendingName = "";
        root.run(name, root.pendingImage);
    }

    function apply(name: string) {
        root.run(name, "");
    }

    // wallust saves the scheme under the image's file name, up to its first dot.
    function generate(image: string) {
        root.run(image.split("/").pop().split(".")[0], image);
    }

    function setBlur(enabled: bool) {
        settings.blur = enabled;
        writeDebounce.restart();
    }

    function setApplyToApps(enabled: bool) {
        settings.applyToApps = enabled;
        writeDebounce.restart();
        // Bring the apps in line with the theme the shell already shows.
        if (enabled)
            root.apply(root.theme);

    }

    Component.onCompleted: settingsFile.text()

    Process {
        id: wallust

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.error = "Could not apply " + root.requested;

            // The watches cannot see a file that did not exist yet.
            applied.reload();
            paletteFile.reload();
            // Deferred: the process may still read as running inside its own
            // exit handler, and run() would queue the request again.
            if (root.pendingName !== "")
                Qt.callLater(root.runPending);

        }

        stderr: SplitParser {
            onRead: (line) => {
                return console.warn("theme:", line);
            }
        }

    }

    Timer {
        id: writeDebounce

        interval: 200
        onTriggered: settingsFile.writeAdapter()
    }

    // Not Quickshell.statePath(): that creates its directory as soon as it is
    // asked, and logs an error in a greeter whose user has no writable home.
    FileView {
        id: settingsFile

        path: root.stateDir + "/quickshell/appearance.json"
        preload: true
        blockLoading: true
        printErrors: false
        watchChanges: false

        adapter: JsonAdapter {
            id: settings

            property bool blur: true
            property bool applyToApps: true
        }

    }

    FileView {
        id: applied

        path: root.stateDir + "/wallust/theme"
        printErrors: false
        watchChanges: true
        onFileChanged: applied.reload()
    }

    FileView {
        id: paletteFile

        path: root.home + "/.cache/wallust/quickshell.json"
        printErrors: false
        watchChanges: true
        onFileChanged: paletteFile.reload()

        adapter: JsonAdapter {
            id: paletteData

            property string background
            property string foreground
            property string cursor
            property string color0
            property string color1
            property string color2
            property string color3
            property string color4
            property string color5
            property string color6
            property string color7
            property string color8
            property string color9
            property string color10
            property string color11
            property string color12
            property string color13
            property string color14
            property string color15
        }

    }

}
