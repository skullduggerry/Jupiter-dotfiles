pragma ComponentBehavior: Bound

import "../services"
import "../style"
import QtQuick

// The calendar dropdown's open tasks, under the day's agenda: every one not
// done yet, whatever day is selected. Those with a due date come first, soonest
// at the top and late ones in the error colour, then those with none, which
// Nextcloud's Tasks app allows.
Item {
    id: root

    readonly property date startOfToday: new Date(Time.now.getFullYear(), Time.now.getMonth(), Time.now.getDate())

    implicitHeight: Style.bar.spacing + Style.border.width + Style.bar.spacing + header.height + list.height

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
        id: header

        height: Style.popup.itemHeight

        anchors {
            top: separator.bottom
            left: parent.left
            right: parent.right
            topMargin: Style.bar.spacing
        }

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Tasks"
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: CalendarService.tasks.length + " open"
            color: Colors.text.muted
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
            top: header.bottom
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
                color: "transparent"
                border.width: Style.border.width
                border.color: taskRow.modelData.colour || Colors.calendar.event

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }

            Text {
                text: taskRow.modelData.summary
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size
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
