import "../services"
import "../style"
import QtQuick

Item {
    id: root

    readonly property bool wantsKeyboard: false
    readonly property int preferredHeight: Style.bar.padding * 2 + header.height + Style.border.width + Style.bar.spacing + Math.max(Style.popup.itemHeight, entries.contentHeight)

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

            Text {
                text: "Notifications"
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

            }

            Text {
                id: clearAll

                visible: NotificationService.count > 0
                text: clearArea.containsMouse ? "Clear all" : NotificationService.count
                color: clearArea.containsMouse ? Colors.text.base : Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

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

            height: Style.border.width
            color: Colors.base.border

            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
            }

        }

        ListView {
            id: entries

            clip: true
            spacing: Style.bar.spacing
            model: NotificationService.list
            visible: entries.count > 0

            anchors {
                top: separator.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.bar.spacing
            }

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
