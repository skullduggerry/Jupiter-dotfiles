pragma ComponentBehavior: Bound

import "../services"
import "../style"
import QtQuick

Item {
    id: root

    implicitHeight: Style.bar.padding * 2 + header.height + weekdays.height + grid.height + Style.bar.spacing + Style.border.width + Style.bar.spacing + agendaHeader.height + root.agendaHeight + status.height
    readonly property int agendaHeight: setup.visible ? setup.implicitHeight + Style.bar.spacing : Math.max(Style.popup.itemHeight, agenda.contentHeight)
    readonly property date today: Time.now
    property date displayedMonth: new Date(root.today.getFullYear(), root.today.getMonth(), 1)
    property date selectedDay: root.today
    readonly property int firstDayOfWeek: Qt.locale().firstDayOfWeek
    readonly property int columns: 7
    readonly property int weekCount: {
        const year = root.displayedMonth.getFullYear();
        const month = root.displayedMonth.getMonth();
        const offset = (new Date(year, month, 1).getDay() - root.firstDayOfWeek + 7) % 7;
        const daysInMonth = new Date(year, month + 1, 0).getDate();
        return Math.ceil((offset + daysInMonth) / root.columns);
    }
    readonly property date gridStart: {
        const first = new Date(root.displayedMonth.getFullYear(), root.displayedMonth.getMonth(), 1);
        const offset = (first.getDay() - root.firstDayOfWeek + 7) % 7;
        return new Date(first.getFullYear(), first.getMonth(), 1 - offset);
    }
    readonly property var selectedEvents: CalendarService.eventsByDay[CalendarService.dayKey(root.selectedDay)] || []
    readonly property bool showingUpcoming: root.selectedEvents.length === 0 && root.upcomingEvents.length > 0
    readonly property var upcomingEvents: {
        const from = new Date(root.selectedDay.getFullYear(), root.selectedDay.getMonth(), root.selectedDay.getDate());
        return CalendarService.events.filter(event => event.end > from).slice(0, Style.calendar.upcomingCount);
    }
    readonly property var agendaEvents: root.showingUpcoming ? root.upcomingEvents : root.selectedEvents

    function dayAt(index: int): date {
        return new Date(root.gridStart.getFullYear(), root.gridStart.getMonth(), root.gridStart.getDate() + index);
    }

    function sameDay(left: date, right: date): bool {
        return left.getFullYear() === right.getFullYear() && left.getMonth() === right.getMonth() && left.getDate() === right.getDate();
    }

    // One dot per event, in its calendar's colour or the accent. Unannotated:
    // qmlformat turns a list<color> return type into a bare list, which the
    // engine then coerces to void at every call.
    function dotColours(day) {
        const events = CalendarService.eventsByDay[CalendarService.dayKey(day)];
        if (events === undefined)
            return [];

        return events.slice(0, Style.calendar.maxDots).map(event => event.colour || Colors.calendar.event);
    }

    function shiftMonth(months: int) {
        root.displayedMonth = new Date(root.displayedMonth.getFullYear(), root.displayedMonth.getMonth() + months, 1);
    }

    function showToday() {
        root.displayedMonth = new Date(root.today.getFullYear(), root.today.getMonth(), 1);
        root.selectedDay = root.today;
    }

    Binding {
        target: CalendarService
        property: "rangeStart"
        value: root.gridStart
    }

    Binding {
        target: CalendarService
        property: "rangeEnd"
        value: root.dayAt(root.columns * root.weekCount + Style.calendar.upcomingLookahead)
    }

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

            height: Style.popup.itemHeight

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            TextButton {
                width: Style.popup.rowIconWidth
                text: "\u{F0141}"
                onClicked: root.shiftMonth(-1)

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }

            TextButton {
                id: month

                anchors.centerIn: parent
                text: Qt.formatDate(root.displayedMonth, "MMMM yyyy")
                color: month.hovered ? Colors.calendar.today : Colors.text.base
                font.pixelSize: Style.text.size
                onClicked: root.showToday()
            }

            TextButton {
                width: Style.popup.rowIconWidth
                horizontalAlignment: Text.AlignRight
                text: "\u{F0142}"
                onClicked: root.shiftMonth(1)

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        Row {
            id: weekdays

            height: Style.calendar.weekdayHeight

            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
            }

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

            readonly property real cellWidth: width / root.columns

            height: root.weekCount * Style.calendar.rowHeight
            columns: root.columns
            rows: root.weekCount

            anchors {
                top: weekdays.bottom
                left: parent.left
                right: parent.right
            }

            WheelHandler {
                onWheel: event => root.shiftMonth(event.angleDelta.y > 0 ? -1 : 1)
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
                    readonly property var dots: root.dotColours(cell.day)

                    width: grid.cellWidth
                    height: Style.calendar.rowHeight

                    Rectangle {
                        id: highlight

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        width: Style.calendar.daySize
                        height: Style.calendar.daySize
                        radius: width / 2
                        color: cell.selected ? Colors.calendar.selected : dayArea.containsMouse ? Colors.base.hover : "transparent"
                        border.width: cell.isToday && !cell.selected ? Style.border.width : 0
                        border.color: Colors.calendar.today

                        Text {
                            anchors.centerIn: parent
                            text: cell.day.getDate()
                            color: cell.selected ? Colors.text.inverted : cell.isToday ? Colors.calendar.today : cell.inMonth ? Colors.text.base : Colors.text.muted
                            font.family: Style.text.font
                            font.pixelSize: Style.text.size
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: highlight.bottom
                        height: Style.calendar.dotRowHeight
                        spacing: Style.calendar.dotSpacing

                        Repeater {
                            model: cell.dots

                            delegate: Rectangle {
                                required property color modelData

                                anchors.verticalCenter: parent.verticalCenter
                                width: Style.calendar.dotSize
                                height: Style.calendar.dotSize
                                radius: width / 2
                                color: cell.inMonth ? modelData : Colors.text.muted
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

            height: Style.border.width
            color: Colors.base.border

            anchors {
                top: grid.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.bar.spacing
            }
        }

        Item {
            id: agendaHeader

            height: Style.popup.itemHeight

            anchors {
                top: separator.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.bar.spacing
            }

            Text {
                id: agendaTitle

                text: root.showingUpcoming ? Qt.formatDate(root.selectedDay, "d MMM") + " · upcoming" : Qt.formatDate(root.selectedDay, "dddd d MMMM")
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size
                elide: Text.ElideRight
                width: parent.width - agendaState.width - Style.widgets.spacing

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }

            Text {
                id: agendaState

                text: CalendarService.loading ? "Syncing…" : CalendarService.status === "ok" ? Qt.formatDateTime(CalendarService.lastUpdated, "HH:mm") : ""
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        Item {
            id: status

            height: statusLabel.visible ? statusLabel.implicitHeight + Style.bar.spacing : 0

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }

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

            clip: true
            model: root.agendaEvents
            visible: count > 0

            anchors {
                top: agendaHeader.bottom
                bottom: status.top
                left: parent.left
                right: parent.right
            }

            delegate: Row {
                id: agendaRow

                required property var modelData

                width: agenda.width
                height: Style.popup.itemHeight
                spacing: Style.widgets.spacing

                Rectangle {
                    id: marker

                    width: Style.calendar.dotSize
                    height: Style.calendar.dotSize
                    radius: width / 2
                    color: agendaRow.modelData.colour || Colors.calendar.event
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: eventTime

                    text: root.showingUpcoming ? Qt.formatDateTime(agendaRow.modelData.start, agendaRow.modelData.allDay ? "ddd d" : "ddd d HH:mm") : agendaRow.modelData.allDay ? "all day" : Qt.formatDateTime(agendaRow.modelData.start, "HH:mm")
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                    width: root.showingUpcoming ? Style.calendar.upcomingTimeWidth : Style.calendar.agendaTimeWidth
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: agendaRow.modelData.summary
                    color: Colors.text.base
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size
                    elide: Text.ElideRight
                    width: agendaRow.width - eventTime.width - marker.width - agendaRow.spacing * 2
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        CalendarSetup {
            id: setup

            visible: CalendarService.status === "unconfigured"

            anchors {
                top: agendaHeader.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.bar.spacing
            }
        }

        Text {
            anchors.centerIn: agenda
            visible: agenda.count === 0 && !setup.visible
            text: CalendarService.status === "error" ? "Calendar unavailable" : CalendarService.loading && CalendarService.events.length === 0 ? "Loading…" : "Nothing scheduled"
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }
    }
}
