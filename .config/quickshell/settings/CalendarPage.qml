import "../panels"
import "../services"
import "../style"
import QtQuick

// How the calendar dropdown lays out its grid (CalendarService): the day each
// week starts on, and whether it shows the month or a few weeks from today's.
ScrollPage {
    id: root

    Section {
        title: "CALENDAR"

        FormCard {
            width: root.columnWidth

            FormRow {
                label: "Week starts on"

                ChoiceField {
                    choices: CalendarService.weekStartChoices
                    current: CalendarService.weekStart
                    onPicked: day => CalendarService.setWeekStart(day)
                }
            }

            FormRow {
                label: "Days shown"

                PillGroup {
                    width: parent.width
                    choices: CalendarService.weekChoices
                    current: CalendarService.shownWeeks
                    onPicked: weeks => CalendarService.setShownWeeks(weeks)
                }
            }
        }

        Text {
            width: root.columnWidth
            wrapMode: Text.WordWrap
            text: "A few weeks start from this one, and the arrows go on by as many."
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
        }
    }
}
