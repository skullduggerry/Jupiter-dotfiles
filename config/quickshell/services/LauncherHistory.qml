// services/LauncherHistory.qml
//
// How often each application has been launched from the launcher, so the
// results can put what you actually use first.
//
// Kept in the shell's state directory rather than its config directory: this
// is data the shell generates about itself, not something anyone edits, and
// `Quickshell.statePath` is where that belongs. JsonAdapter does the
// serialising, so there is no hand-written JSON on either side.
//
// QML singletons are built on first access, so nothing here happens until the
// launcher actually opens — but once it does, the file is loaded *before*
// anything is written back. Without that the adapter starts empty, and the
// first launch of a session overwrites every count from the last one.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // FileView starts an asynchronous load as soon as its path is set, and
    // only honours `blockLoading` when text() or data() is called. A QML
    // singleton is built on its first use, so that first use lands in the
    // same tick as construction — early enough to read an empty adapter and
    // then write it back over a file full of real counts. This one forced,
    // blocking read closes that window.
    //
    // At construction rather than lazily from count(): count() is called from
    // the launcher's `allApps` binding, and a guard flag read and written
    // during a binding evaluation is a binding loop as far as Qt is
    // concerned — it says so in the log.
    Component.onCompleted: historyFile.text()

    // Launch key -> number of launches. Read through a function rather than
    // exposed directly, because an entry with no launches has no key at all.
    //
    // The key is the entry's `execString`, not its desktop id:
    // `DesktopEntries` can look an entry up `byId`, but `DesktopEntry` does
    // not expose an id of its own on this version, and keying on `name` would
    // move with the locale. The Exec line is what actually identifies the
    // program being started.
    function count(key: string): int {
        const stored = counts.launches[key]
        return stored === undefined ? 0 : stored
    }

    // Ordering for the launcher's list: most-used first, alphabetical among
    // entries used the same number of times (which includes everything never
    // launched, so an untouched install still reads as an alphabetical list).
    function compare(left: DesktopEntry, right: DesktopEntry): int {
        const difference = root.count(right.execString) - root.count(left.execString)
        if (difference !== 0) return difference
        return left.name.localeCompare(right.name)
    }

    function record(key: string) {
        if (key === "") return
        // Reassigned rather than mutated: JsonAdapter notices a property
        // change, not a change made inside the object it already holds.
        const updated = Object.assign({}, counts.launches)
        updated[key] = root.count(key) + 1
        counts.launches = updated
        writeDebounce.restart()
    }

    // Writes are coalesced rather than issued per record. writeAdapter() is
    // asynchronous, and a second write started while the first is in flight
    // resyncs the adapter from the snapshot the first one took — silently
    // reverting anything recorded in between.
    Timer {
        id: writeDebounce
        interval: 200
        onTriggered: historyFile.writeAdapter()
    }

    FileView {
        id: historyFile

        path: Quickshell.statePath("launcher-history.json")
        // Load as soon as this singleton exists, and block until it has:
        // record() merges into whatever is already here, so it has to be
        // here first.
        preload: true
        blockLoading: true
        // The file legitimately doesn't exist until the first launch, and a
        // missing state file is not something to complain about in the log.
        printErrors: false
        // Nothing else writes it, so there is nothing to watch for.
        watchChanges: false

        adapter: JsonAdapter {
            id: counts

            property var launches: ({})
        }
    }
}
