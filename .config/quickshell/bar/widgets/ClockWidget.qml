import "../../services"
import "../../style"
import QtQuick
import Quickshell

Item {
    id: root

    required property ShellScreen screen

    implicitWidth: clock.implicitWidth + Style.widgets.padding * 2
    implicitHeight: Style.bar.height

    Text {
        id: clock

        anchors.centerIn: parent
        text: Time.time
        color: Colors.text.base
        font.family: Style.text.font
        font.pixelSize: Style.text.size
    }

    MouseArea {
        anchors.fill: parent
        onClicked: DropdownState.toggle(DropdownState.zoneCalendar, root.screen)
    }
}
