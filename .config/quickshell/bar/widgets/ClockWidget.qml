import "../../services"
import "../../style"
import QtQuick
import Quickshell

Item {
    id: root

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

    }

    MouseArea {
        anchors.fill: parent
        onClicked: DropdownState.toggle(DropdownState.zoneCalendar, root.screen)
    }

}
