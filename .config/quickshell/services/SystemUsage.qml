// services/SystemUsage.qml
//
// CPU and memory load, for the bar's two meters.
//
// This is the one place in the shell that genuinely has to poll. Everything
// else reacts to an event — a Hyprland socket message, a DBus signal, a
// UPower property change — but the kernel exposes load as a pair of counters
// in /proc and nothing tells you when they move, so a timer it is (llm.md
// §15 permits what has no event-driven alternative; `interval` keeps it
// cheap, and `active` stops it entirely when nothing is displaying it).
//
// Read through FileView rather than a `cat` subprocess: /proc files are
// in-memory, so a blocking read costs a syscall rather than a fork.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Fraction of CPU time spent busy since the previous sample, 0.0-1.0.
    // Zero until two samples exist, since it is a delta, not a level.
    property real cpu: 0

    // Fraction of RAM in use, 0.0-1.0. "In use" is total minus *available*
    // rather than minus free: page cache is free for the asking, and counting
    // it as used would pin every idle machine near 100%.
    property real memory: 0

    // Set by whatever is displaying these. The bar always is, so in practice
    // this runs for the life of the shell — but it means a future surface
    // that shows load can gate the timer the way CalendarService does.
    property bool active: false

    // Slow enough not to matter, fast enough that the number isn't stale by
    // the time you look at it.
    readonly property int interval: 3000

    // Previous /proc/stat totals, for the delta. Not readonly and not
    // derived: a counter difference is state, not a binding.
    property real previousBusy: 0
    property real previousTotal: 0

    // /proc/stat's first line is
    //   cpu  user nice system idle iowait irq softirq steal guest guest_nice
    // in jiffies since boot. Busy is everything that isn't idle or waiting on
    // IO; both counters are cumulative, so only their difference means
    // anything.
    function sampleCpu() {
        statFile.reload()
        const fields = statFile.text().split("\n")[0].trim().split(/\s+/)
        if (fields[0] !== "cpu") return

        let total = 0
        for (let index = 1; index < fields.length; index++) total += Number(fields[index])
        const idle = Number(fields[4]) + Number(fields[5])
        const busy = total - idle

        const totalDelta = total - root.previousTotal
        const busyDelta = busy - root.previousBusy
        root.previousTotal = total
        root.previousBusy = busy

        // The first sample has nothing to subtract from, and a zero delta
        // would divide by zero on a machine so idle the counters didn't move.
        if (totalDelta > 0) root.cpu = Math.max(0, Math.min(1, busyDelta / totalDelta))
    }

    function sampleMemory() {
        memoryFile.reload()
        const lines = memoryFile.text().split("\n")
        let total = 0
        let available = 0
        for (let index = 0; index < lines.length; index++) {
            const line = lines[index]
            if (line.startsWith("MemTotal:")) total = Number(line.split(/\s+/)[1])
            else if (line.startsWith("MemAvailable:")) available = Number(line.split(/\s+/)[1])
            if (total > 0 && available > 0) break
        }
        if (total > 0) root.memory = Math.max(0, Math.min(1, (total - available) / total))
    }

    function sample() {
        root.sampleCpu()
        root.sampleMemory()
    }

    // Take one immediately so the bar doesn't show 0% for the first interval.
    onActiveChanged: if (root.active) root.sample()

    // blockAllReads because reload() has to have landed by the time text() is
    // read on the next line; for a /proc file that is a synchronous read of a
    // buffer the kernel already has.
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
