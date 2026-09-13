// bar/widgets/Time.qml
pragma Singleton

import Quickshell.Io
import Quickshell
import QtQuick

Singleton {
    id: root

    // Flip to true for a ticking seconds display in the bar. SystemClock only
    // wakes as often as its precision demands, so leaving this off keeps the
    // shell from being woken sixty times a minute to redraw a digit nobody
    // asked for (llm.md §15).
    readonly property bool showSeconds: false

    // The live date itself, for consumers that need the value rather than a
    // label — the calendar's month grid asks which cell is today, and wants
    // that answer to change at midnight.
    readonly property date now: clock.date

    readonly property string time: Qt.formatDateTime(clock.date, root.showSeconds ? "HH:mm:ss" : "HH:mm")

    // Short date for the bar, e.g. "Sat 12 Sep", in the system locale.
    readonly property string date: Qt.formatDateTime(clock.date, "ddd d MMM")

    SystemClock {
        id: clock
        precision: root.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }
}
