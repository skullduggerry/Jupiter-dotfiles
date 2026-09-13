// panels/NotificationPanel.qml
import QtQuick
import "../services"
import "../style"

Item {
    id: root

    readonly property bool wantsKeyboard: false

    readonly property int preferredHeight: Style.bar.padding * 2
        + header.height
        + Style.border.width
        + Style.bar.spacing
        + Math.max(Style.popup.itemHeight, entries.contentHeight)

    Item {
        anchors.fill: parent
        anchors.margins: Style.bar.padding

        Item {
            id: header
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: Style.popup.itemHeight

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "Notifications"
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size
            }

            Text {
                id: clearAll
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                visible: NotificationService.count > 0
                text: clearArea.containsMouse ? "Clear all" : NotificationService.count
                color: clearArea.containsMouse ? Colors.text.base : Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize

                MouseArea {
                    id: clearArea
                    anchors.fill: parent
                    anchors.margins: -Style.widgets.spacing
                    hoverEnabled: true
                    onClicked: NotificationService.dismissAll()
                }
            }
        }

        Rectangle {
            id: separator
            anchors { top: header.bottom; left: parent.left; right: parent.right }
            height: Style.border.width
            color: Colors.base.border
        }

        ListView {
            id: entries
            anchors {
                top: separator.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.bar.spacing
            }
            clip: true
            spacing: Style.bar.spacing
            model: NotificationService.list
            visible: entries.count > 0

            delegate: NotificationEntry {
                width: entries.width
            }
        }

        Text {
            anchors.centerIn: parent
            visible: entries.count === 0
            text: NotificationService.doNotDisturb ? "Do not disturb" : "No notifications"
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }
    }
}
