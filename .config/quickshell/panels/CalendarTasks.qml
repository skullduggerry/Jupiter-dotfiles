pragma ComponentBehavior: Bound

import "../services"
import "../style"
import QtQuick

// The calendar dropdown's open tasks, under the day's agenda: every one not
// done yet, whatever day is selected. Those with a due date come first, soonest
// at the top and late ones in the error colour, then those with none, which
// Nextcloud's Tasks app allows. Clicking a task's ring marks it done; only the
// ring, since a two-finger swipe over the list clicks first.
Item {
    id: root

    readonly property date startOfToday: new Date(Time.now.getFullYear(), Time.now.getMonth(), Time.now.getDate())

    implicitHeight: Style.bar.spacing + Style.border.width + Style.bar.spacing + heading.height + list.height

    Rectangle {
        id: separator

        height: Style.border.width
        color: Colors.base.border

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: Style.bar.spacing
        }
    }

    Item {
        id: heading

        height: Style.popup.itemHeight

        anchors {
            top: separator.bottom
            left: parent.left
            right: parent.right
            topMargin: Style.bar.spacing
        }

        Text {
            id: title

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Tasks"
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }

        Text {
            id: count

            readonly property bool failed: CalendarService.completeProblem !== ""

            anchors.left: title.right
            anchors.right: parent.right
            anchors.leftMargin: Style.widgets.spacing
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: count.failed ? "Not marked done: " + CalendarService.completeProblem : CalendarService.tasks.length + " open"
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: count.failed ? Colors.status.error : Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
        }
    }

    ListView {
        id: list

        height: Math.min(CalendarService.tasks.length, Style.calendar.taskRows) * Style.popup.itemHeight
        clip: true
        interactive: list.contentHeight > list.height
        boundsBehavior: Flickable.StopAtBounds
        model: CalendarService.tasks

        anchors {
            top: heading.bottom
            left: parent.left
            right: parent.right
        }

        delegate: Item {
            id: taskRow

            required property var modelData
            readonly property bool dated: taskRow.modelData.due !== null
            // A task due on a day is late once that day is over.
            readonly property bool late: taskRow.dated && (taskRow.modelData.allDay ? taskRow.modelData.due < root.startOfToday : taskRow.modelData.due < Time.now)

            width: list.width
            height: Style.popup.itemHeight

            Rectangle {
                id: ring

                width: Style.calendar.taskRingSize
                height: Style.calendar.taskRingSize
                radius: width / 2
                // Filled under the pointer: what clicking will do to it.
                color: done.containsMouse ? ring.border.color : "transparent"
                border.width: Style.border.width
                border.color: taskRow.modelData.colour || Colors.calendar.event

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                MouseArea {
                    id: done

                    anchors.fill: parent
                    anchors.margins: -Style.widgets.spacing
                    enabled: taskRow.modelData.href !== ""
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: CalendarService.complete(taskRow.modelData.href)
                }
            }

            Text {
                text: taskRow.modelData.summary
                textFormat: Text.PlainText
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size
                font.strikeout: done.containsMouse
                elide: Text.ElideRight

                anchors {
                    left: ring.right
                    right: due.left
                    leftMargin: Style.widgets.spacing
                    rightMargin: Style.widgets.spacing
                    verticalCenter: parent.verticalCenter
                }
            }

            Text {
                id: due

                text: taskRow.dated ? Qt.formatDateTime(taskRow.modelData.due, taskRow.modelData.allDay ? "d MMM" : "d MMM HH:mm") : ""
                color: taskRow.late ? Colors.status.error : Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
