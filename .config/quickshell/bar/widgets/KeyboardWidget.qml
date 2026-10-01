import "../../icons"
import "../../services"
import "../../style"
import QtQuick
import Quickshell

// The keyboard layout in use, once there is more than one: a click switches
// to the next, a right click opens the dropdown's workspace zone, which lists
// them all.
Item {
    id: root

    required property ShellScreen screen

    visible: KeyboardLayout.layouts.length > 1
    implicitWidth: visible ? row.implicitWidth + Style.widgets.padding * 2 : 0
    implicitHeight: Style.bar.height

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Style.widgets.spacing

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.keyboard
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: KeyboardLayout.label
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                DropdownState.toggle(DropdownState.zoneWorkspaces, root.screen);
            else
                KeyboardLayout.next();
        }
    }
}
