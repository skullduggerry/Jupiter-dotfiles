pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpu: 0
    property real memory: 0
    property bool active: false
    readonly property int interval: 3000
    property real previousBusy: 0
    property real previousTotal: 0

    function sampleCpu() {
        statFile.reload();
        const fields = statFile.text().split("\n")[0].trim().split(/\s+/);
        if (fields[0] !== "cpu")
            return ;

        let total = 0;
        for (let index = 1; index < fields.length; index++) total += Number(fields[index])
        const idle = Number(fields[4]) + Number(fields[5]);
        const busy = total - idle;
        const totalDelta = total - root.previousTotal;
        const busyDelta = busy - root.previousBusy;
        root.previousTotal = total;
        root.previousBusy = busy;
        if (totalDelta > 0)
            root.cpu = Math.max(0, Math.min(1, busyDelta / totalDelta));

    }

    function sampleMemory() {
        memoryFile.reload();
        const lines = memoryFile.text().split("\n");
        let total = 0;
        let available = 0;
        for (let index = 0; index < lines.length; index++) {
            const line = lines[index];
            if (line.startsWith("MemTotal:"))
                total = Number(line.split(/\s+/)[1]);
            else if (line.startsWith("MemAvailable:"))
                available = Number(line.split(/\s+/)[1]);
            if (total > 0 && available > 0)
                break;

        }
        if (total > 0)
            root.memory = Math.max(0, Math.min(1, (total - available) / total));

    }

    function sample() {
        root.sampleCpu();
        root.sampleMemory();
    }

    onActiveChanged: {
        if (root.active)
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

    Timer {
        interval: root.interval
        repeat: true
        running: root.active
        onTriggered: root.sample()
    }

}
