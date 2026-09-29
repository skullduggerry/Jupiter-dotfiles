pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.UPower

Singleton {
    id: root

    // Kelvin; the Displays page sets it, from 2500 (warm) to 6500 (neutral).
    readonly property int nightLightTemperature: settings.nightLightTemperature
    readonly property int nightLightWarmest: 2500
    readonly property int nightLightCoolest: 6500
    readonly property bool nightLight: sunset.running
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool airplaneMode: !Networking.wifiEnabled && (root.adapter === null || !root.adapter.enabled)
    // Whether cliphist is being fed; the Clipboard page lists what it holds.
    readonly property bool clipboardHistory: textHistory.running
    readonly property bool recording: recorder.running
    // The file the running (or the last) recording goes to.
    property string recordingFile: ""
    // Caffeine keeps the session from going idle, so hypridle neither locks it
    // nor turns the screens off, for caffeineMinutes or, at 0, until turned
    // off. The bars hold the inhibitor, which needs a window. Only the length
    // is saved: a new shell locks as usual.
    property bool caffeine: false
    // The minute it ends, counted from the epoch; 0 while it has no end.
    property int caffeineEnd: 0
    readonly property int caffeineMinutes: settings.caffeineMinutes
    readonly property list<int> caffeineChoices: [15, 30, 60, 120, 0]
    readonly property bool anyOn: root.nightLight || root.airplaneMode || NotificationService.doNotDisturb || root.recording || root.caffeine
    // power-profiles-daemon's modes, Performance only where the hardware has it.
    readonly property var profileChoices: (PowerProfiles.hasPerformanceProfile ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance] : [PowerProfile.PowerSaver, PowerProfile.Balanced]).map(profile => ({
                label: root.profileName(profile),
                value: profile
            }))

    // Hyprland resets the colour matrix when hyprsunset disconnects, so
    // stopping the process is the off switch.
    function setNightLight(enabled: bool) {
        settings.nightLight = enabled;
        writeDebounce.restart();
        sunset.running = enabled;
    }

    // A running hyprsunset takes the new value over its IPC; the command line
    // has it for the next start.
    function setNightLightTemperature(kelvin: int) {
        settings.nightLightTemperature = Math.max(root.nightLightWarmest, Math.min(root.nightLightCoolest, kelvin));
        writeDebounce.restart();
        if (sunset.running)
            retint.restart();
    }

    // wl-paste hands every copy to cliphist, text and images each with a
    // watcher of its own; like Night Light, the tile shows the processes.
    function setClipboardHistory(enabled: bool) {
        settings.clipboardHistory = enabled;
        writeDebounce.restart();
        textHistory.running = enabled;
        imageHistory.running = enabled;
    }

    // The focused monitor, into the videos folder; SIGINT is what makes
    // wf-recorder finish the file rather than leave it cut off.
    function setRecording(enabled: bool) {
        if (enabled && !recorder.running && Hyprland.focusedMonitor !== null) {
            recorder.output = Hyprland.focusedMonitor.name;
            root.recordingFile = "";
            recorder.running = true;
        } else if (!enabled && recorder.running) {
            recorder.signal(2);
        }
    }

    // Through NetworkManager and BlueZ rather than rfkill, so the Wi-Fi and
    // Bluetooth pages always agree with this tile.
    function setAirplaneMode(enabled: bool) {
        Networking.wifiEnabled = !enabled;
        if (root.adapter !== null)
            root.adapter.enabled = !enabled;
    }

    function profileName(profile: int): string {
        switch (profile) {
        case PowerProfile.PowerSaver:
            return "Power Saver";
        case PowerProfile.Performance:
            return "Performance";
        default:
            return "Balanced";
        }
    }

    // Up to the clock's next minute, the only moments it can end on.
    function setCaffeine(enabled: bool) {
        root.caffeine = enabled;
        root.caffeineEnd = enabled && root.caffeineMinutes > 0 ? Math.ceil(Date.now() / 60000) + root.caffeineMinutes : 0;
    }

    // The next length, counted from now if Caffeine is on.
    function cycleCaffeineMinutes() {
        const choices = root.caffeineChoices;
        settings.caffeineMinutes = choices[(choices.indexOf(root.caffeineMinutes) + 1) % choices.length];
        writeDebounce.restart();
        if (root.caffeine)
            root.setCaffeine(true);
    }

    Component.onCompleted: {
        settingsFile.text();
        sunset.running = settings.nightLight;
        textHistory.running = settings.clipboardHistory;
        imageHistory.running = settings.clipboardHistory;
    }

    // With a parent-death signal: an orphan left by a killed shell would keep
    // tinting and block the next shell's hyprsunset from starting.
    Process {
        id: sunset

        command: ["setpriv", "--pdeathsig", "TERM", "hyprsunset", "--temperature", String(root.nightLightTemperature)]
        onExited: (exitCode, exitStatus) => {
            if (settings.nightLight)
                console.warn("night light: hyprsunset exited with status", exitCode);
        }
    }

    // The bar's clock ticks every minute by the wall clock, so Caffeine ends
    // on time across a suspend too.
    Connections {
        target: Time

        function onNowChanged() {
            if (root.caffeineEnd !== 0 && Math.round(Time.now.getTime() / 60000) >= root.caffeineEnd)
                root.setCaffeine(false);
        }
    }

    // At most one hyprctl call per moment while the slider is dragged.
    Timer {
        id: retint

        interval: 150
        onTriggered: Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(root.nightLightTemperature)])
    }

    // cliphist is checked for first: without it wl-paste would run on, the
    // tile would read on, and every copy would fail unseen.
    Process {
        id: textHistory

        command: ["sh", "-c", "command -v cliphist >/dev/null || exit 127; exec setpriv --pdeathsig TERM wl-paste --type text --watch cliphist store"]
        onExited: (exitCode, exitStatus) => {
            if (settings.clipboardHistory)
                console.warn("clipboard: the history watcher exited with status", exitCode);
        }
    }

    Process {
        id: imageHistory

        command: ["sh", "-c", "command -v cliphist >/dev/null || exit 127; exec setpriv --pdeathsig TERM wl-paste --type image --watch cliphist store"]
    }

    Process {
        id: recorder

        property string output: ""

        command: [Quickshell.shellDir + "/services/screen-record.sh", recorder.output]
        onExited: (exitCode, exitStatus) => {
            if (root.recordingFile === "" || exitCode !== 0) {
                console.warn("screen record: wf-recorder exited with status", exitCode);
                return;
            }
            saved.command = ["notify-send", "--app-name=Screen Record", "--icon=video-x-generic", "Recording saved", root.recordingFile];
            saved.running = true;
        }

        // The script's first line; anything wf-recorder prints comes after.
        stdout: SplitParser {
            onRead: line => {
                if (root.recordingFile === "")
                    root.recordingFile = line;
            }
        }
    }

    Process {
        id: saved
    }

    Timer {
        id: writeDebounce

        interval: 200
        onTriggered: settingsFile.writeAdapter()
    }

    FileView {
        id: settingsFile

        path: Quickshell.statePath("quick-toggles.json")
        preload: true
        blockLoading: true
        printErrors: false
        watchChanges: false

        adapter: JsonAdapter {
            id: settings

            property bool nightLight: false
            property int nightLightTemperature: 4000
            property bool clipboardHistory: false
            property int caffeineMinutes: 60
        }
    }
}
