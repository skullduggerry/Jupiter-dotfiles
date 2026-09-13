// services/Brightness.qml
//
// Display backlight level, read from sysfs.
//
// Quickshell has no brightness API, and neither UPower nor logind will tell
// you when the level changes, so this reads `/sys/class/backlight/<device>/`
// directly through FileView. Writes go out through `swayosd-client`, which
// the compositor's own brightness keys already use (see
// ../hypr/modules/keybinds.lua) — it owns the privileged write path, shows
// the on-screen level, and keeps one mechanism instead of two.
//
// The level is re-read on a timer rather than watched. A FileView watch was
// tried first and never fired; sysfs attributes support poll() on an open
// descriptor, not the inotify events QFileSystemWatcher subscribes to, so
// there is nothing to watch. The brightness keys go through swayosd rather
// than through this shell, so their changes have to be noticed rather than
// observed. It is one four-byte read of an in-memory file, and only while
// something is displaying it.
//
// A machine with no backlight — a desktop, or this laptop with its lid shut
// and only external monitors attached — has an empty /sys/class/backlight and
// `available` stays false, which is what hides the bar widget.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // The backlight device directory, e.g. "/sys/class/backlight/intel_backlight".
    // Empty until the probe below finds one.
    property string device: ""

    readonly property bool available: root.device !== "" && root.maximum > 0

    property int level: 0
    property int maximum: 0

    // 0.0-1.0, which is what the bar's ramp wants.
    readonly property real fraction: root.available ? root.level / root.maximum : 0

    // Percentage step for a scroll tick, matching the keybinds' feel.
    readonly property int step: 5

    // Short enough that pressing a brightness key and glancing at the bar
    // agree with each other.
    readonly property int interval: 1000

    // Set by whatever is displaying it. The probe and the file watch both
    // wait for this, so a shell nobody asked about brightness costs nothing.
    property bool active: false

    // reload() then text(), the same shape SystemUsage uses on /proc: with
    // blockAllReads the pair is synchronous, so the value is in hand by the
    // next line. These are only ever called from the timer below — never from
    // a property change handler, because a handler runs before the bindings
    // that depend on it are re-evaluated, and the FileView's path is one of
    // those.
    function readLevel() {
        levelFile.reload()
        const text = levelFile.text().trim()
        if (text !== "") root.level = Number(text)
    }

    function readMaximum() {
        maximumFile.reload()
        const text = maximumFile.text().trim()
        if (text !== "") root.maximum = Number(text)
    }

    // swayosd takes a signed percentage. It writes the sysfs file, which the
    // watch below then reports back — the level is never assumed here, only
    // read.
    function adjust(percent: int) {
        if (!root.available) return
        Quickshell.execDetached(["swayosd-client", "--brightness",
                                 (percent > 0 ? "+" : "") + percent])
    }

    onActiveChanged: if (root.active && root.device === "") probe.running = true

    // One process, once, the first time something asks. There is no API for
    // listing a directory — FileView reads a file — and the set of backlight
    // devices doesn't change while the session runs.
    // triggeredOnStart is what does the first read: it fires on the tick
    // after `device` lands, by which time the FileViews' paths have caught up
    // with it. max_brightness never changes while the machine runs, so it is
    // read once and then left alone.
    Timer {
        interval: root.interval
        repeat: true
        triggeredOnStart: true
        running: root.active && root.device !== ""

        onTriggered: {
            if (root.maximum === 0) root.readMaximum()
            root.readLevel()
        }
    }

    Process {
        id: probe

        command: ["ls", "-1", "/sys/class/backlight"]
        stdout: StdioCollector { id: probeOutput }

        onExited: (exitCode, exitStatus) => {
            const names = probeOutput.text.trim().split("\n").filter(name => name !== "")
            // More than one is possible (an integrated panel plus a DDC
            // bridge); the first is the one swayosd will drive by default.
            if (names.length > 0) root.device = "/sys/class/backlight/" + names[0]
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
