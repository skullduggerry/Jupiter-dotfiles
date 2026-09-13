// services/CalendarService.qml
//
// Upcoming events from a Nextcloud calendar, for CalendarPanel.
//
// The CalDAV talking is done by services/nextcloud-calendar.py, invoked
// through Process: QML never sees the server URL or the password, and a
// CalDAV REPORT plus recurrence expansion is not something to reimplement in
// QML property bindings. The script's contract is one JSON object on stdout,
// which is also the vocabulary `status` uses.
//
// Nothing here runs unless a calendar surface is on screen: `active` gates
// both the first fetch and the refresh interval, so a closed dropdown costs
// nothing (llm.md §15).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // "idle" until the first fetch, then the helper's own status: "loading"
    // while a request is out, then "ok", "unconfigured" or "error".
    property string status: "idle"

    // Why the last fetch didn't work, for display next to the agenda. Empty
    // whenever `status` is "ok".
    property string message: ""

    // Events overlapping [rangeStart, rangeEnd), sorted by start. `start` and
    // `end` are real Date objects, converted once here rather than in every
    // binding that wants to compare them.
    property var events: []

    property date lastUpdated: new Date(0)

    // The window the helper is asked for. CalendarPanel points these at the
    // month it displays; the defaults cover the current month so a consumer
    // that never navigates still gets something sensible.
    property date rangeStart: new Date(new Date().getFullYear(), new Date().getMonth(), 1)
    property date rangeEnd: new Date(new Date().getFullYear(), new Date().getMonth() + 1, 1)

    // Set by a consumer while it's on screen. Nothing in the bar displays
    // event data, so with every calendar surface closed this service makes no
    // requests at all.
    property bool active: false

    // A range change that arrives mid-request would otherwise be dropped,
    // leaving the panel showing a month it didn't ask for.
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

    // The key `eventsByDay` groups by. An explicit format rather than a
    // locale one, because it's an identity, not something anyone reads.
    function dayKey(day: date): string {
        return Qt.formatDate(day, "yyyy-MM-dd")
    }

    // Events grouped by every local day they cover: a multi-day event appears
    // under each of its days. Grouping once per fetch lets the month grid
    // answer 42 cells with 42 lookups instead of scanning the event list 42
    // times — and it keeps the day-overlap rule in exactly one place.
    //
    // An all-day event's end is exclusive (its DTEND is the following
    // midnight), so a two-day holiday lands on exactly its two days, and a
    // zero-length reminder still lands on the day it starts.
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
            // The helper prints JSON on every path it controls, so landing
            // here means it died before it could: a missing python3, a
            // traceback, a killed process.
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
            // Nothing is going to arrive until the user sets this up, so
            // don't leave a previous fetch's events sitting there.
            root.events = []
        }

        if (root.refetchWanted) root.refresh()
    }

    Process {
        id: fetcher

        command: ["python3", Quickshell.shellDir + "/services/nextcloud-calendar.py",
                  "--start", Qt.formatDate(root.rangeStart, "yyyy-MM-dd"),
                  "--end", Qt.formatDate(root.rangeEnd, "yyyy-MM-dd")]

        // StdioCollector holds the exited signal until the streams close, so
        // both texts are complete by the time applyResult runs.
        stdout: StdioCollector { id: fetchOutput }
        stderr: StdioCollector { id: fetchError }

        onExited: (exitCode, exitStatus) => root.applyResult(exitCode, fetchOutput.text, fetchError.text)
    }

    Timer {
        id: rangeDebounce
        // Paging through months fires a burst of range changes; coalesce them
        // instead of starting a request per click.
        interval: 250
        onTriggered: if (root.active) root.refresh()
    }

    Timer {
        // CalDAV has no push, so a surface left open has to re-ask.
        interval: 15 * 60 * 1000
        repeat: true
        running: root.active
        onTriggered: root.refresh()
    }
}
