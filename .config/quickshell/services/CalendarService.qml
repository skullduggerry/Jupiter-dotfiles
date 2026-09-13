// services/CalendarService.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string status: "idle"

    property string message: ""

    property var events: []

    property date lastUpdated: new Date(0)

    property date rangeStart: new Date(new Date().getFullYear(), new Date().getMonth(), 1)
    property date rangeEnd: new Date(new Date().getFullYear(), new Date().getMonth() + 1, 1)

    property bool active: false

    property bool refetchWanted: false

    readonly property bool loading: status === "loading"

    function refresh() {
        if (fetcher.running) {
            root.refetchWanted = true
            return
        }
        root.refetchWanted = false
        root.status = "loading"
        fetcher.running = true
    }

    function dayKey(day: date): string {
        return Qt.formatDate(day, "yyyy-MM-dd")
    }

    readonly property var eventsByDay: {
        const grouped = {}
        for (let index = 0; index < root.events.length; index++) {
            const event = root.events[index]
            let day = new Date(event.start.getFullYear(), event.start.getMonth(), event.start.getDate())
            do {
                const key = root.dayKey(day)
                if (grouped[key] === undefined) grouped[key] = []
                grouped[key].push(event)
                day = new Date(day.getFullYear(), day.getMonth(), day.getDate() + 1)
            } while (day < event.end && day < root.rangeEnd)
        }
        return grouped
    }

    onActiveChanged: if (root.active) root.refresh()
    onRangeStartChanged: rangeDebounce.restart()
    onRangeEndChanged: rangeDebounce.restart()

    function applyResult(exitCode: int, output: string, errorOutput: string) {
        let payload = null
        try {
            payload = JSON.parse(output)
        } catch (parseError) {
            root.status = "error"
            root.message = errorOutput.trim().split("\n").pop()
                || "calendar helper exited " + exitCode + " without output"
            return
        }

        root.status = payload.status
        root.message = payload.message || ""

        if (payload.status === "ok") {
            root.events = payload.events.map(event => ({
                summary: event.summary,
                location: event.location,
                calendar: event.calendar,
                allDay: event.allDay,
                start: new Date(event.start),
                end: new Date(event.end)
            }))
            root.lastUpdated = new Date()
        } else if (payload.status === "unconfigured") {
            root.events = []
        }

        if (root.refetchWanted) root.refresh()
    }

    Process {
        id: fetcher

        command: ["python3", Quickshell.shellDir + "/services/nextcloud-calendar.py",
                  "--start", Qt.formatDate(root.rangeStart, "yyyy-MM-dd"),
                  "--end", Qt.formatDate(root.rangeEnd, "yyyy-MM-dd")]

        stdout: StdioCollector { id: fetchOutput }
        stderr: StdioCollector { id: fetchError }

        onExited: (exitCode, exitStatus) => root.applyResult(exitCode, fetchOutput.text, fetchError.text)
    }

    Timer {
        id: rangeDebounce
        interval: 250
        onTriggered: if (root.active) root.refresh()
    }

    Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: root.active
        onTriggered: root.refresh()
    }
}
