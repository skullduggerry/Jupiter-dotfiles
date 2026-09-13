// dropdown/CalendarPanel.qml
//
// Middle zone of the swipe dropdown: a month grid with a dot under every day
// that has events, plus an agenda for the selected day.
//
// The grid drives the fetch window: CalendarService is asked for exactly the
// 42 days on screen, so paging to another month refetches that month and
// nothing else. `active` is held by a Binding for the panel's lifetime, which
// is what stops the service polling once the dropdown closes.
import QtQuick
import "../services"
import "../style"
// The Time singleton lives with the clock widget it was written for; the
// month grid needs the same live date to know which cell is today.
import "../bar/widgets"

Item {
    id: root

    // Part of the zone-panel contract Dropdown.qml relies on: only the Wi-Fi
    // panel ever needs the keyboard.
    readonly property bool wantsKeyboard: false

    readonly property date today: Time.now

    // First of the month on display. Paging moves this by a month.
    property date displayedMonth: new Date(root.today.getFullYear(), root.today.getMonth(), 1)
    property date selectedDay: root.today

    // Qt.locale().firstDayOfWeek is Sunday-based, but the offset below is
    // taken modulo 7, so a locale reporting Sunday as 7 lands on the same
    // column either way.
    readonly property int firstDayOfWeek: Qt.locale().firstDayOfWeek
    readonly property int columns: 7
    readonly property int rows: 6

    // The selected day's events, straight out of the service's grouping.
    readonly property var selectedEvents:
        CalendarService.eventsByDay[CalendarService.dayKey(root.selectedDay)] || []

    // Top-left cell of the grid: the start of the week containing the first
    // of the month, which is usually in the previous month.
    readonly property date gridStart: {
        const first = new Date(root.displayedMonth.getFullYear(), root.displayedMonth.getMonth(), 1)
        const offset = (first.getDay() - root.firstDayOfWeek + 7) % 7
        return new Date(first.getFullYear(), first.getMonth(), 1 - offset)
    }

    // Every function whose value is used in a binding carries its return
    // type: the QML engine treats an unannotated one as returning void and
    // logs an error per call site (once per cell, here).
    function dayAt(index: int): date {
        return new Date(root.gridStart.getFullYear(), root.gridStart.getMonth(), root.gridStart.getDate() + index)
    }

    function sameDay(left: date, right: date): bool {
        return left.getFullYear() === right.getFullYear()
            && left.getMonth() === right.getMonth()
            && left.getDate() === right.getDate()
    }

    function shiftMonth(months: int) {
        root.displayedMonth = new Date(root.displayedMonth.getFullYear(),
                                       root.displayedMonth.getMonth() + months, 1)
    }

    // Ask the service for precisely the days the grid shows.
    Binding {
        target: CalendarService
        property: "rangeStart"
        value: root.gridStart
    }

    Binding {
        target: CalendarService
        property: "rangeEnd"
        value: root.dayAt(root.columns * root.rows)
    }

    // Held only while this panel exists; the service goes quiet again when
    // the Binding is destroyed with it.
    Binding {
        target: CalendarService
        property: "active"
        value: true
    }

    Item {
        anchors.fill: parent
        anchors.margins: Style.bar.padding

        Item {
            id: header
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: Style.popup.itemHeight

            Text {
                id: previousMonth
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "" // chevron-left
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
                width: Style.popup.rowIconWidth
                horizontalAlignment: Text.AlignLeft

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.shiftMonth(-1)
                }
            }

            // Also the way back to the current month, which is otherwise a
            // lot of chevron clicks away.
            Text {
                anchors.centerIn: parent
                text: Qt.formatDate(root.displayedMonth, "MMMM yyyy")
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.displayedMonth = new Date(root.today.getFullYear(), root.today.getMonth(), 1)
                        root.selectedDay = root.today
                    }
                }
            }

            Text {
                id: nextMonth
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: "" // chevron-right
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
                width: Style.popup.rowIconWidth
                horizontalAlignment: Text.AlignRight

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.shiftMonth(1)
                }
            }
        }

        // Weekday names come from the grid's own first week rather than from
        // Locale.dayName(), whose day numbering differs from JS Date's.
        Row {
            id: weekdays
            anchors { top: header.bottom; left: parent.left; right: parent.right }
            height: Style.calendar.weekdayHeight

            Repeater {
                model: root.columns

                delegate: Text {
                    required property int index

                    width: grid.cellWidth
                    height: weekdays.height
                    text: Qt.formatDate(root.dayAt(index), "ddd")
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Grid {
            id: grid
            anchors { top: weekdays.bottom; left: parent.left; right: parent.right }
            height: root.rows * Style.calendar.rowHeight
            columns: root.columns
            rows: root.rows

            readonly property real cellWidth: width / root.columns

            Repeater {
                model: root.columns * root.rows

                delegate: Rectangle {
                    id: cell
                    required property int index

                    readonly property date day: root.dayAt(cell.index)
                    readonly property bool inMonth: cell.day.getMonth() === root.displayedMonth.getMonth()
                    readonly property bool isToday: root.sameDay(cell.day, root.today)
                    readonly property bool selected: root.sameDay(cell.day, root.selectedDay)
                    readonly property bool hasEvents:
                        CalendarService.eventsByDay[CalendarService.dayKey(cell.day)] !== undefined

                    width: grid.cellWidth
                    height: Style.calendar.rowHeight
                    radius: Style.bar.radius / 2
                    color: cell.selected ? Colors.base.hover : "transparent"
                    border.width: cell.isToday ? Style.border.width : 0
                    border.color: Colors.calendar.today

                    Text {
                        anchors.centerIn: parent
                        text: cell.day.getDate()
                        // Days spilling in from the neighbouring months stay
                        // legible but clearly secondary.
                        color: cell.inMonth ? Colors.text.base : Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.size
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Style.border.width * 2
                        visible: cell.hasEvents
                        width: Style.calendar.dotSize
                        height: Style.calendar.dotSize
                        radius: width / 2
                        color: Colors.calendar.event
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.selectedDay = cell.day
                    }
                }
            }
        }

        Rectangle {
            id: separator
            anchors { top: grid.bottom; left: parent.left; right: parent.right; topMargin: Style.bar.spacing }
            height: Style.border.width
            color: Colors.base.border
        }

        Item {
            id: agendaHeader
            anchors { top: separator.bottom; left: parent.left; right: parent.right; topMargin: Style.bar.spacing }
            height: Style.popup.itemHeight

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: Qt.formatDate(root.selectedDay, "dddd d MMMM")
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size
            }

            Text {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                // Only the fetch state worth reacting to gets a word here;
                // "ok" needs none, since the agenda below says it all.
                text: CalendarService.loading ? "Syncing…"
                    : CalendarService.status === "ok" ? Qt.formatDateTime(CalendarService.lastUpdated, "HH:mm")
                    : ""
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
            }
        }

        // Whatever the last fetch had to say for itself: a setup hint while
        // nothing is configured, the failure otherwise (llm.md §14).
        //
        // The label is wrapped in an Item that takes its height rather than
        // having its own `height` bound to its own `implicitHeight`: assigning
        // a height to a wrapping Text relayouts it, which updates
        // implicitHeight, which is a binding loop. Reading the child's
        // implicit height from the parent only goes one way.
        Item {
            id: status
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: statusLabel.visible ? statusLabel.implicitHeight : 0

            Text {
                id: statusLabel
                width: parent.width
                visible: CalendarService.message !== ""
                text: CalendarService.message
                color: CalendarService.status === "error" ? Colors.status.error : Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
                wrapMode: Text.Wrap
                maximumLineCount: 3
            }
        }

        ListView {
            id: agenda
            anchors {
                top: agendaHeader.bottom
                bottom: status.top
                left: parent.left
                right: parent.right
            }
            clip: true
            model: root.selectedEvents
            visible: count > 0

            delegate: Row {
                id: agendaRow
                required property var modelData

                width: agenda.width
                height: Style.popup.itemHeight
                spacing: Style.widgets.spacing

                Text {
                    id: eventTime
                    text: agendaRow.modelData.allDay
                        ? "all day"
                        : Qt.formatDateTime(agendaRow.modelData.start, "HH:mm")
                    color: Colors.calendar.event
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: agendaRow.modelData.summary
                    color: Colors.text.base
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size
                    elide: Text.ElideRight
                    width: agendaRow.width - eventTime.width - agendaRow.spacing
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Text {
            anchors.centerIn: agenda
            visible: agenda.count === 0
            text: CalendarService.status === "unconfigured" ? "Calendar not set up"
                : CalendarService.status === "error" ? "Calendar unavailable"
                : CalendarService.loading && CalendarService.events.length === 0 ? "Loading…"
                : "Nothing scheduled"
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }
    }
}
