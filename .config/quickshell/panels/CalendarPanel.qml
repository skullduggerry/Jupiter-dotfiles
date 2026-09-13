// panels/CalendarPanel.qml
//
// Middle zone of the swipe dropdown: a month grid with a dot under every day
// that has events, and an agenda underneath it.
//
// The grid drives the fetch window: CalendarService is asked for exactly the
// days on screen, so paging to another month refetches that month and nothing
// else. `active` is held by a Binding for the panel's lifetime, which is what
// stops the service polling once the dropdown closes.
//
// The grid draws only the weeks the month actually occupies (four to six),
// and the panel reports the height all of that adds up to, so a short month
// doesn't leave a blank row and an empty day doesn't leave a blank panel.
import QtQuick
import "../services"
import "../style"

Item {
    id: root

    // Part of the zone-panel contract Dropdown.qml relies on: only the Wi-Fi
    // panel ever needs the keyboard.
    readonly property bool wantsKeyboard: false

    // The other half of that contract. Everything between the panel's own
    // padding, added up — the grid's row count is part of it, so the panel
    // shrinks by a row when a month fits in five weeks.
    readonly property int preferredHeight: Style.bar.padding * 2
        + header.height
        + weekdays.height
        + grid.height
        + Style.bar.spacing + Style.border.width + Style.bar.spacing
        + agendaHeader.height
        + root.agendaHeight
        + status.height

    // What the agenda list needs, never less than one row so the empty-state
    // line below it has somewhere to sit.
    readonly property int agendaHeight: Math.max(Style.popup.itemHeight, agenda.contentHeight)

    readonly property date today: Time.now

    // First of the month on display. Paging moves this by a month.
    property date displayedMonth: new Date(root.today.getFullYear(), root.today.getMonth(), 1)
    property date selectedDay: root.today

    // Qt.locale().firstDayOfWeek is Sunday-based, but the offset below is
    // taken modulo 7, so a locale reporting Sunday as 7 lands on the same
    // column either way.
    readonly property int firstDayOfWeek: Qt.locale().firstDayOfWeek
    readonly property int columns: 7

    // How many week rows this month actually occupies. A 28-day February
    // starting on the first column needs four; a 31-day month starting on the
    // last needs six. Drawing a fixed six left an entirely out-of-month row
    // under most months.
    readonly property int weekCount: {
        const year = root.displayedMonth.getFullYear()
        const month = root.displayedMonth.getMonth()
        const offset = (new Date(year, month, 1).getDay() - root.firstDayOfWeek + 7) % 7
        // Day 0 of the next month is the last day of this one.
        const daysInMonth = new Date(year, month + 1, 0).getDate()
        return Math.ceil((offset + daysInMonth) / root.columns)
    }

    // Top-left cell of the grid: the start of the week containing the first
    // of the month, which is usually in the previous month.
    readonly property date gridStart: {
        const first = new Date(root.displayedMonth.getFullYear(), root.displayedMonth.getMonth(), 1)
        const offset = (first.getDay() - root.firstDayOfWeek + 7) % 7
        return new Date(first.getFullYear(), first.getMonth(), 1 - offset)
    }

    // The selected day's events, straight out of the service's grouping.
    readonly property var selectedEvents:
        CalendarService.eventsByDay[CalendarService.dayKey(root.selectedDay)] || []

    // With nothing on the selected day, the agenda lists what is coming
    // instead of an empty box. Limited to the fetched window — the same days
    // the grid shows — so it never claims to know about a month nobody asked
    // the server for.
    readonly property bool showingUpcoming: root.selectedEvents.length === 0
        && root.upcomingEvents.length > 0

    readonly property var upcomingEvents: {
        const from = new Date(root.selectedDay.getFullYear(),
                              root.selectedDay.getMonth(),
                              root.selectedDay.getDate())
        // CalendarService.events arrives sorted by start.
        return CalendarService.events
            .filter(event => event.end > from)
            .slice(0, Style.calendar.upcomingCount)
    }

    readonly property var agendaEvents: root.showingUpcoming ? root.upcomingEvents : root.selectedEvents

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

    // How many dots a day's cell draws, capped so a busy day doesn't spill
    // out of a 42px column.
    function dotCount(day: date): int {
        const events = CalendarService.eventsByDay[CalendarService.dayKey(day)]
        if (events === undefined) return 0
        return Math.min(events.length, Style.calendar.maxDots)
    }

    function shiftMonth(months: int) {
        root.displayedMonth = new Date(root.displayedMonth.getFullYear(),
                                       root.displayedMonth.getMonth() + months, 1)
    }

    function showToday() {
        root.displayedMonth = new Date(root.today.getFullYear(), root.today.getMonth(), 1)
        root.selectedDay = root.today
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
        value: root.dayAt(root.columns * root.weekCount)
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
                text: "" // chevron-left
                color: previousArea.containsMouse ? Colors.text.base : Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
                width: Style.popup.rowIconWidth
                horizontalAlignment: Text.AlignLeft

                MouseArea {
                    id: previousArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.shiftMonth(-1)
                }
            }

            // Also the way back to the current month, which is otherwise a
            // lot of chevron clicks away — so it highlights on hover like the
            // button it is.
            Text {
                anchors.centerIn: parent
                text: Qt.formatDate(root.displayedMonth, "MMMM yyyy")
                color: monthArea.containsMouse ? Colors.calendar.today : Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size

                MouseArea {
                    id: monthArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.showToday()
                }
            }

            Text {
                id: nextMonth
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: "" // chevron-right
                color: nextArea.containsMouse ? Colors.text.base : Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
                width: Style.popup.rowIconWidth
                horizontalAlignment: Text.AlignRight

                MouseArea {
                    id: nextArea
                    anchors.fill: parent
                    hoverEnabled: true
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
            height: root.weekCount * Style.calendar.rowHeight
            columns: root.columns
            rows: root.weekCount

            readonly property real cellWidth: width / root.columns

            // Scrolling over the month pages it, which beats aiming at a
            // 16px chevron. A pointer handler rather than a MouseArea because
            // every cell already has one of those and would eat the event.
            WheelHandler {
                onWheel: (event) => root.shiftMonth(event.angleDelta.y > 0 ? -1 : 1)
            }

            Repeater {
                model: root.columns * root.weekCount

                delegate: Item {
                    id: cell
                    required property int index

                    readonly property date day: root.dayAt(cell.index)
                    readonly property bool inMonth: cell.day.getMonth() === root.displayedMonth.getMonth()
                    readonly property bool isToday: root.sameDay(cell.day, root.today)
                    readonly property bool selected: root.sameDay(cell.day, root.selectedDay)
                    readonly property int dots: root.dotCount(cell.day)

                    width: grid.cellWidth
                    height: Style.calendar.rowHeight

                    Rectangle {
                        id: highlight

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        width: Style.calendar.daySize
                        height: Style.calendar.daySize
                        radius: width / 2
                        color: cell.selected ? Colors.calendar.selected
                            : dayArea.containsMouse ? Colors.base.hover
                            : "transparent"
                        // Today keeps a ring even when it isn't the selected
                        // day, so the grid always says where "now" is.
                        border.width: cell.isToday && !cell.selected ? Style.border.width : 0
                        border.color: Colors.calendar.today

                        Text {
                            anchors.centerIn: parent
                            text: cell.day.getDate()
                            // Days spilling in from the neighbouring months
                            // stay legible but clearly secondary.
                            color: cell.selected ? Colors.text.inverted
                                : cell.isToday ? Colors.calendar.today
                                : cell.inMonth ? Colors.text.base
                                : Colors.text.muted
                            font.family: Style.text.font
                            font.pixelSize: Style.text.size
                        }
                    }

                    // One dot per event, up to maxDots — enough to tell a
                    // free day from a full one without reading the agenda.
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: highlight.bottom
                        height: Style.calendar.dotRowHeight
                        spacing: Style.calendar.dotSpacing

                        Repeater {
                            model: cell.dots

                            delegate: Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: Style.calendar.dotSize
                                height: Style.calendar.dotSize
                                radius: width / 2
                                color: cell.inMonth ? Colors.calendar.event : Colors.text.muted
                            }
                        }
                    }

                    MouseArea {
                        id: dayArea
                        anchors.fill: parent
                        hoverEnabled: true
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
                id: agendaTitle
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                // Says plainly when the rows below belong to days other than
                // the selected one.
                text: root.showingUpcoming
                    ? Qt.formatDate(root.selectedDay, "d MMM") + " · upcoming"
                    : Qt.formatDate(root.selectedDay, "dddd d MMMM")
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size
                elide: Text.ElideRight
                width: parent.width - agendaState.width - Style.widgets.spacing
            }

            Text {
                id: agendaState
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
            // Carries its own leading gap so the agenda above doesn't butt up
            // against it, and so preferredHeight accounts for that gap
            // without the panel adding a second margin of its own.
            height: statusLabel.visible ? statusLabel.implicitHeight + Style.bar.spacing : 0

            Text {
                id: statusLabel
                anchors.bottom: parent.bottom
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
            model: root.agendaEvents
            visible: count > 0

            delegate: Row {
                id: agendaRow
                required property var modelData

                width: agenda.width
                height: Style.popup.itemHeight
                spacing: Style.widgets.spacing

                Text {
                    id: eventTime
                    // An upcoming row belongs to some other day, so it says
                    // which one; a row on the selected day only needs a time.
                    text: root.showingUpcoming
                        ? Qt.formatDateTime(agendaRow.modelData.start,
                                            agendaRow.modelData.allDay ? "ddd d" : "ddd d HH:mm")
                        : agendaRow.modelData.allDay ? "all day"
                        : Qt.formatDateTime(agendaRow.modelData.start, "HH:mm")
                    color: Colors.calendar.event
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                    // Fixed, so the summaries line up into a column rather
                    // than stepping in and out with the label's length.
                    width: root.showingUpcoming ? Style.calendar.upcomingTimeWidth : Style.calendar.agendaTimeWidth
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
