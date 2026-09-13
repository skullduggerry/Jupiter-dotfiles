// bar/widgets/ClockWidget.qml
//
// Time and date in the bar's centre zone. Clicking it opens the calendar
// dropdown, which is the same surface the three-finger swipe over the middle
// of the screen opens (see dropdown/Dropdown.qml).
import QtQuick
import Quickshell
import "../../services"
import "../../style"

Item {
    id: root

    // Which monitor's dropdown to open; forwarded from BarContent.qml.
    required property ShellScreen screen

    implicitWidth: row.implicitWidth + Style.widgets.padding * 2
    implicitHeight: Style.bar.height

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Style.widgets.spacing

        Text {
            text: Time.time
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.size
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: Time.date
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: DropdownState.toggle(DropdownState.zoneCalendar, root.screen)
    }
}
