pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpu: 0
    property real memory: 0
    property bool active: false
    // SystemPanels on screen, in the usage dropdown and on the Settings app's
    // About page, each counting itself. Everything below `cores` is only read
    // while there is one, and more often: the bar's meters need none of it.
    property int viewers: 0
    readonly property bool detailed: root.viewers > 0
    readonly property int interval: root.detailed ? 1000 : 3000
    property real previousBusy: 0
    property real previousTotal: 0
    // The same busy share as `cpu`, one per online core. Cheap enough to keep
    // current, so an opening panel already has a real sample to show.
    property var cores: []
    property var previousCoreBusy: []
    property var previousCoreTotal: []
    // /proc/meminfo, in KiB.
    property real memoryTotal: 0
    property real memoryAvailable: 0
    property real memoryCache: 0
    property real swapTotal: 0
    property real swapFree: 0
    property string model: ""
    // MHz, averaged over the cores.
    property real frequency: 0
    // °C, and below zero when no CPU sensor was found.
    property real temperature: -1
    // The 1, 5 and 15 minute load averages.
    property var load: []
    property real uptime: 0
    property string sensor: ""
    property bool sensorSearched: false

    function sampleCpu() {
        statFile.reload();
        const lines = statFile.text().split("\n");
        const cores = [];
        const coreBusy = [];
        const coreTotal = [];
        // The aggregate line, then one per online core, then nothing about CPUs.
        for (let index = 0; index < lines.length; index++) {
            const fields = lines[index].trim().split(/\s+/);
            if (!fields[0].startsWith("cpu"))
                break;

            let total = 0;
            for (let field = 1; field < fields.length; field++)
                total += Number(fields[field]);
            const busy = total - Number(fields[4]) - Number(fields[5]);
            if (fields[0] === "cpu") {
                const totalDelta = total - root.previousTotal;
                const busyDelta = busy - root.previousBusy;
                root.previousTotal = total;
                root.previousBusy = busy;
                if (totalDelta > 0)
                    root.cpu = Math.max(0, Math.min(1, busyDelta / totalDelta));

                continue;
            }
            // Keyed by the core's number, which stays put when another goes offline.
            const core = Number(fields[0].slice(3));
            const totalDelta = total - (root.previousCoreTotal[core] || 0);
            const busyDelta = busy - (root.previousCoreBusy[core] || 0);
            coreTotal[core] = total;
            coreBusy[core] = busy;
            cores.push(totalDelta > 0 ? Math.max(0, Math.min(1, busyDelta / totalDelta)) : 0);
        }
        root.previousCoreTotal = coreTotal;
        root.previousCoreBusy = coreBusy;
        root.cores = cores;
    }

    function sampleMemory() {
        memoryFile.reload();
        const values = {};
        const lines = memoryFile.text().split("\n");
        for (let index = 0; index < lines.length; index++) {
            const fields = lines[index].split(/\s+/);
            values[fields[0]] = Number(fields[1]);
        }
        const total = values["MemTotal:"] || 0;
        if (total === 0)
            return;

        root.memoryTotal = total;
        root.memoryAvailable = values["MemAvailable:"] || 0;
        // What `free` calls buff/cache.
        root.memoryCache = (values["Buffers:"] || 0) + (values["Cached:"] || 0) + (values["SReclaimable:"] || 0);
        root.swapTotal = values["SwapTotal:"] || 0;
        root.swapFree = values["SwapFree:"] || 0;
        root.memory = Math.max(0, Math.min(1, (total - root.memoryAvailable) / total));
    }

    function sampleDetails() {
        cpuinfoFile.reload();
        const lines = cpuinfoFile.text().split("\n");
        let sum = 0;
        let count = 0;
        for (let index = 0; index < lines.length; index++) {
            const line = lines[index];
            if (line.startsWith("cpu MHz")) {
                sum += Number(line.split(":")[1]);
                count++;
            } else if (root.model === "" && line.startsWith("model name")) {
                root.model = root.shortModel(line.split(":")[1]);
            }
        }
        root.frequency = count > 0 ? sum / count : 0;
        loadFile.reload();
        root.load = loadFile.text().split(" ").slice(0, 3).map(Number);
        uptimeFile.reload();
        root.uptime = Number(uptimeFile.text().split(" ")[0]);
        if (root.sensor !== "") {
            sensorFile.reload();
            root.temperature = Number(sensorFile.text()) / 1000;
        }
    }

    // "AMD Ryzen 5 7640U w/ Radeon 760M Graphics" is "AMD Ryzen 5 7640U";
    // Intel's "(R)", "(TM)" and "CPU @ 2.60GHz" go the same way.
    function shortModel(name: string): string {
        return name.replace(/\((R|TM)\)/g, "").replace(/\s+(w\/|with)\s.*$/, "").replace(/\s+CPU\b.*$/, "").replace(/\s+\d+-Core Processor$/, "").replace(/\s+/g, " ").trim();
    }

    function sample() {
        root.sampleCpu();
        root.sampleMemory();
        if (root.detailed)
            root.sampleDetails();
    }

    onActiveChanged: {
        if (root.active)
            root.sample();
    }
    onDetailedChanged: {
        if (!root.detailed)
            return;

        if (!root.sensorSearched) {
            root.sensorSearched = true;
            sensors.running = true;
        }
        root.sample();
    }

    FileView {
        id: statFile

        path: "/proc/stat"
        blockLoading: true
        blockAllReads: true
    }

    FileView {
        id: memoryFile

        path: "/proc/meminfo"
        blockLoading: true
        blockAllReads: true
    }

    FileView {
        id: cpuinfoFile

        path: "/proc/cpuinfo"
        blockLoading: true
        blockAllReads: true
    }

    FileView {
        id: loadFile

        path: "/proc/loadavg"
        blockLoading: true
        blockAllReads: true
    }

    FileView {
        id: uptimeFile

        path: "/proc/uptime"
        blockLoading: true
        blockAllReads: true
    }

    // sysfs: read on each sample like the /proc files, since it cannot be watched.
    FileView {
        id: sensorFile

        path: root.sensor
        blockLoading: true
        blockAllReads: true
        printErrors: false
    }

    // hwmon numbers follow probe order and change between boots, so the CPU's
    // sensor is found by its driver's name, once.
    Process {
        id: sensors

        command: ["sh", "-c", "grep -H . /sys/class/hwmon/hwmon*/name"]

        stdout: StdioCollector {
            id: sensorList

            onStreamFinished: {
                const drivers = {};
                const lines = sensorList.text.split("\n");
                for (let index = 0; index < lines.length; index++) {
                    const separator = lines[index].lastIndexOf(":");
                    if (separator > 0)
                        drivers[lines[index].slice(separator + 1)] = lines[index].slice(0, separator).replace(/\/name$/, "");
                }
                // AMD, AMD's out-of-tree driver, Intel, then ARM boards.
                const preferred = ["k10temp", "zenpower", "coretemp", "cpu_thermal"];
                for (let index = 0; index < preferred.length; index++) {
                    if (drivers[preferred[index]] !== undefined) {
                        root.sensor = drivers[preferred[index]] + "/temp1_input";
                        return;
                    }
                }
            }
        }
    }

    Timer {
        interval: root.interval
        repeat: true
        running: root.active
        onTriggered: root.sample()
    }
}
