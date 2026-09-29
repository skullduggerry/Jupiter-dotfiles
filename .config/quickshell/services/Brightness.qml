pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string deviceName: ""
    readonly property string device: root.deviceName === "" ? "" : "/sys/class/backlight/" + root.deviceName
    readonly property bool available: root.device !== "" && root.maximum > 0
    property int level: 0
    property int maximum: 0
    readonly property real fraction: root.available ? root.level / root.maximum : 0
    readonly property int step: 5
    // A floor, so the slider cannot black the screen.
    readonly property int minimum: 5
    readonly property int interval: 1000
    readonly property int settleInterval: 250
    readonly property int writeInterval: 50
    property int pending: -1
    property bool active: false

    function readLevel() {
        levelFile.reload();
        const text = levelFile.text().trim();
        if (text !== "")
            root.level = Number(text);
    }

    function readMaximum() {
        maximumFile.reload();
        const text = maximumFile.text().trim();
        if (text !== "")
            root.maximum = Number(text);
    }

    // brightnessctl reaches the backlight through logind: no group, no daemon.
    function write() {
        if (root.pending < 0)
            return;

        Quickshell.execDetached(["brightnessctl", "-c", "backlight", "-d", root.deviceName, "-q", "set", root.pending + "%"]);
        root.pending = -1;
    }

    // sysfs shows a write only on the next poll: the UI moves at once, and
    // reading waits until the write has landed.
    function request(target: int) {
        if (!root.available)
            return;

        const clamped = Math.max(root.minimum, Math.min(100, target));
        root.level = Math.round(clamped / 100 * root.maximum);
        root.pending = clamped;
        settling.restart();
        if (writes.running)
            return;

        root.write();
        writes.start();
    }

    function adjust(percent: int) {
        root.request(Math.round(root.fraction * 100) + percent);
    }

    function setPercent(percent: int) {
        root.request(percent);
    }

    onActiveChanged: {
        if (root.active && root.deviceName === "")
            probe.running = true;
    }

    Timer {
        interval: root.interval
        repeat: true
        triggeredOnStart: true
        running: root.active && root.device !== ""
        onTriggered: {
            if (root.maximum === 0)
                root.readMaximum();

            if (!settling.running)
                root.readLevel();
        }
    }

    // While this runs, a write owns `level` and sysfs still has the old one.
    Timer {
        id: settling

        interval: root.settleInterval
    }

    // A drag requests on every pointer event; the newest goes out at most
    // this often.
    Timer {
        id: writes

        interval: root.writeInterval
        repeat: true
        onTriggered: {
            if (root.pending < 0) {
                writes.stop();
                return;
            }
            root.write();
        }
    }

    Process {
        id: probe

        command: ["ls", "-1", "/sys/class/backlight"]
        onExited: (exitCode, exitStatus) => {
            const names = probeOutput.text.trim().split("\n").filter(name => name !== "");
            if (names.length > 0)
                root.deviceName = names[0];
        }

        stdout: StdioCollector {
            id: probeOutput
        }
    }

    FileView {
        id: maximumFile

        path: root.device === "" ? "" : root.device + "/max_brightness"
        blockLoading: true
        blockAllReads: true
        printErrors: false
    }

    FileView {
        id: levelFile

        path: root.device === "" ? "" : root.device + "/brightness"
        blockLoading: true
        blockAllReads: true
        printErrors: false
    }
}
