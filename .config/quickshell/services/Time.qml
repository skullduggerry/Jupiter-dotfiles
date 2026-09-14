pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property bool showSeconds: false
    readonly property date now: clock.date
    readonly property string time: Qt.formatDateTime(clock.date, root.showSeconds ? "HH:mm:ss" : "HH:mm")
    readonly property string date: Qt.formatDateTime(clock.date, "ddd d MMM")

    SystemClock {
        id: clock

        precision: root.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

}
