pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string device: ""
    readonly property bool available: root.device !== "" && root.maximum > 0
    property int level: 0
    property int maximum: 0
    readonly property real fraction: root.available ? root.level / root.maximum : 0
    readonly property int step: 5
    readonly property int interval: 1000
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

    function adjust(percent: int) {
        if (!root.available)
            return ;

        Quickshell.execDetached(["swayosd-client", "--brightness", (percent > 0 ? "+" : "") + percent]);
    }

    function setPercent(percent: int) {
        if (!root.available)
            return ;

        const clamped = Math.max(0, Math.min(100, percent));
        Quickshell.execDetached(["swayosd-client", "--brightness", String(clamped)]);
    }

    onActiveChanged: {
        if (root.active && root.device === "")
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

            root.readLevel();
        }
    }

    Process {
        id: probe

        command: ["ls", "-1", "/sys/class/backlight"]
        onExited: (exitCode, exitStatus) => {
            const names = probeOutput.text.trim().split("\n").filter((name) => {
                return name !== "";
            });
            if (names.length > 0)
                root.device = "/sys/class/backlight/" + names[0];

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
