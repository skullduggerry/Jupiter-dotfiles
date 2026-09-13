// panels/NotificationEntry.qml
import QtQuick
import Quickshell.Services.Notifications
import Quickshell.Widgets
import "../style"

Item {
    id: root

    required property Notification modelData

    signal dismissed()

    readonly property bool urgent: root.modelData.urgency === NotificationUrgency.Critical
    readonly property string iconSource: root.modelData.image !== "" ? root.modelData.image : root.modelData.appIcon

    implicitHeight: body.implicitHeight

    Column {
        id: body

        width: parent.width
        spacing: Style.widgets.spacing

        Item {
            width: parent.width
            height: Style.text.smallSize

            IconImage {
                id: appIcon
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                visible: root.iconSource !== ""
                implicitSize: Style.text.smallSize
                source: root.iconSource
            }

            Text {
                anchors {
                    left: appIcon.visible ? appIcon.right : parent.left
                    leftMargin: appIcon.visible ? Style.widgets.spacing : 0
                    right: closeButton.left
                    rightMargin: Style.widgets.spacing
                    verticalCenter: parent.verticalCenter
                }
                text: root.modelData.appName
                color: root.urgent ? Colors.notification.urgent : Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
                elide: Text.ElideRight
            }

            Text {
                id: closeButton
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: ""
                color: closeArea.containsMouse ? Colors.text.base : Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    anchors.margins: -Style.widgets.spacing
                    hoverEnabled: true
                    onClicked: {
                        root.modelData.dismiss()
                        root.dismissed()
                    }
                }
            }
        }

        Text {
            width: parent.width
            visible: root.modelData.summary !== ""
            text: root.modelData.summary
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.size
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: root.modelData.body !== ""
            text: root.modelData.body
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            textFormat: Text.StyledText
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: Style.notifications.bodyMaxLines
        }

        Row {
            visible: root.modelData.actions.length > 0
            spacing: Style.widgets.spacing

            Repeater {
                model: root.modelData.actions

                delegate: Rectangle {
                    id: action
                    required property NotificationAction modelData

                    width: actionLabel.implicitWidth + Style.bar.padding * 2
                    height: Style.notifications.actionHeight
                    radius: Style.popup.rowRadius
                    color: actionArea.containsMouse ? Colors.base.hover : "transparent"
                    border.width: Style.border.width
                    border.color: Colors.base.border

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: action.modelData.text
                        color: Colors.text.base
                        font.family: Style.text.font
                        font.pixelSize: Style.text.smallSize
                    }

                    MouseArea {
                        id: actionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            action.modelData.invoke()
                            root.dismissed()
                        }
                    }
                }
            }
        }
    }
}
