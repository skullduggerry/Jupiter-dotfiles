pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The palette Colors derives from, and what changes it: config/wallust/apply.sh
// renders it and records the theme (.github/THEMING.md). Nothing runs until a
// theme is picked: the greeter gets a copy of style/ and must only read.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string scripts: (Quickshell.env("XDG_CONFIG_HOME") || root.home + "/.config") + "/wallust"
    readonly property string stateDir: Quickshell.env("XDG_STATE_HOME") || root.home + "/.local/state"
    // The first line of apply.sh's record; its own default before it ran.
    readonly property string theme: applied.text().split("\n")[0] || "Oxocarbon-Dark"
    readonly property bool blur: settings.blur
    // Hyprland's decoration:blur size, behind every translucent surface:
    // set live, and kept in blur.lua for config/hypr/styles/layout.lua.
    readonly property int blurSize: settings.blurSize
    // Over blur, how much of a surface is the theme's background: at least
    // darkTint or lightTint, as the theme is dark or light, which Static keeps
    // to and Adaptive (true) raises where the wallpaper behind needs more
    // (Colors.base.opacity).
    readonly property bool adaptiveTint: settings.adaptiveTint
    readonly property real darkTint: settings.darkTint
    readonly property real lightTint: settings.lightTint
    // screen name -> {bright, dark}: the wallpaper behind that screen's panels
    // at its brightest and darkest, as its bar measured it (BackdropProbe).
    // Colors takes the least readable; the greeter never measures.
    property var backdrops: ({})
    readonly property bool applyToApps: settings.applyToApps
    // The Settings app's choices. The accent is one of Colors.accentNames, the
    // font a family name, empty for the shell's own.
    readonly property string accent: settings.accent
    readonly property string font: settings.font
    // The last light and the last dark theme applied, whatever applied them:
    // what the Settings app's Light and Dark switch between.
    readonly property string lightTheme: settings.lightTheme
    readonly property string darkTheme: settings.darkTheme
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
            return;
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

    function setBlurSize(size: int) {
        settings.blurSize = size;
        writeDebounce.restart();
        // At most one hyprctl call per interval while the slider is dragged.
        if (!blurThrottle.running)
            blurThrottle.start();
    }

    function setAdaptiveTint(enabled: bool) {
        settings.adaptiveTint = enabled;
        writeDebounce.restart();
    }

    function setTint(light: bool, tint: real) {
        if (light)
            settings.lightTint = tint;
        else
            settings.darkTint = tint;
        writeDebounce.restart();
    }

    function setBackdrop(screen: string, bright: color, dark: color) {
        const next = Object.assign({}, root.backdrops);
        next[screen] = {
            bright: bright,
            dark: dark
        };
        root.backdrops = next;
    }

    function clearBackdrop(screen: string) {
        const next = Object.assign({}, root.backdrops);
        delete next[screen];
        root.backdrops = next;
    }

    function setAccent(name: string) {
        settings.accent = name;
        writeDebounce.restart();
        root.reapplyToApps();
    }

    function setFont(family: string) {
        settings.font = family;
        writeDebounce.restart();
        root.reapplyToApps();
    }

    // apply.sh hands the accent and the font to the apps' templates, so they
    // follow only when the theme is applied again.
    function reapplyToApps() {
        if (settings.applyToApps)
            root.apply(root.theme);
    }

    function setApplyToApps(enabled: bool) {
        settings.applyToApps = enabled;
        writeDebounce.restart();
        // Bring the apps in line with the theme the shell already shows.
        if (enabled)
            root.apply(root.theme);
    }

    Component.onCompleted: settingsFile.text()
    onThemeChanged: rememberDebounce.restart()

    Process {
        id: wallust

        // What the Settings app has just picked, which the state file may not
        // hold yet: its writes are debounced. apply.sh prefers these.
        environment: ({
                APPEARANCE_ACCENT: settings.accent,
                APPEARANCE_FONT: settings.font
            })
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
            onRead: line => console.warn("theme:", line)
        }
    }

    Timer {
        id: blurThrottle

        interval: 150
        onTriggered: {
            const blur = `{ size = ${settings.blurSize} }`;
            keptBlur.setText(`-- Written by the shell (config/quickshell/style/Theme.qml).\nreturn ${blur}\n`);
            Quickshell.execDetached(["hyprctl", "eval", `hl.config({ decoration = { blur = ${blur} } })`]);
        }
    }

    Timer {
        id: writeDebounce

        interval: 200
        onTriggered: settingsFile.writeAdapter()
    }

    // The theme's name and its palette come from two files, written one after
    // the other, so the pair is only read once both have settled. Never with no
    // palette: the greeter cannot read one, and must not write.
    Timer {
        id: rememberDebounce

        interval: 300
        onTriggered: {
            if (paletteData.background === "")
                return;

            const light = Qt.color(paletteData.background).hslLightness > 0.5;
            if ((light ? settings.lightTheme : settings.darkTheme) === root.theme)
                return;

            if (light)
                settings.lightTheme = root.theme;
            else
                settings.darkTheme = root.theme;
            writeDebounce.restart();
        }
    }

    Connections {
        function onBackgroundChanged() {
            rememberDebounce.restart();
        }

        target: paletteData
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
            property int blurSize: 6
            property bool adaptiveTint: true
            property real darkTint: 0.6
            property real lightTint: 0.8
            property bool applyToApps: true
            property string accent: "blue"
            property string font: ""
            property string lightTheme: "Catppuccin-Latte"
            property string darkTheme: "Oxocarbon-Dark"
        }
    }

    FileView {
        id: keptBlur

        path: root.stateDir + "/quickshell/blur.lua"
        preload: false
        printErrors: false
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
