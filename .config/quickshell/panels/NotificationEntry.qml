pragma ComponentBehavior: Bound

import "../style"
import QtQuick
import Quickshell.Services.Notifications
import Quickshell.Widgets

Item {
    id: root

    required property Notification modelData
    readonly property bool urgent: root.modelData.urgency === NotificationUrgency.Critical
    readonly property string iconSource: root.modelData.image !== "" ? root.modelData.image : root.modelData.appIcon
    // A toast waits while a reply is being written into it.
    readonly property bool replying: reply.editing || reply.text !== ""

    signal dismissed

    function sendReply() {
        if (reply.text.trim() === "")
            return;

        root.modelData.sendInlineReply(reply.text);
        root.dismissed();
    }

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

                visible: root.iconSource !== ""
                implicitSize: Style.text.smallSize
                source: root.iconSource

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }

            Text {
                text: root.modelData.appName
                color: root.urgent ? Colors.notification.urgent : Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
                elide: Text.ElideRight

                anchors {
                    left: appIcon.visible ? appIcon.right : parent.left
                    leftMargin: appIcon.visible ? Style.widgets.spacing : 0
                    right: closeButton.left
                    rightMargin: Style.widgets.spacing
                    verticalCenter: parent.verticalCenter
                }
            }

            TextButton {
                id: closeButton

                text: "\u{F0156}"
                onClicked: {
                    root.modelData.dismiss();
                    root.dismissed();
                }

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
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
                            action.modelData.invoke();
                            root.dismissed();
                        }
                    }
                }
            }
        }

        // KDE's inline reply: what is typed here goes back to the app, which
        // is how a messenger answers from its notification.
        Item {
            visible: root.modelData.hasInlineReply
            width: parent.width
            height: visible ? Style.notifications.actionHeight : 0

            InputField {
                id: reply

                height: parent.height
                placeholder: root.modelData.inlineReplyPlaceholder || "Reply"
                icon: "\u{F045A}"
                onAccepted: root.sendReply()

                anchors {
                    left: parent.left
                    right: send.left
                    rightMargin: Style.widgets.spacing
                }
            }

            Rectangle {
                id: send

                width: height
                height: parent.height
                radius: Style.popup.rowRadius
                color: sendArea.containsMouse ? Colors.base.hover : "transparent"
                border.width: Style.border.width
                border.color: Colors.base.border

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                Text {
                    anchors.centerIn: parent
                    text: "\u{F048A}"
                    color: reply.text.trim() === "" ? Colors.text.muted : Colors.icon.active
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                }

                MouseArea {
                    id: sendArea

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.sendReply()
                }
            }
        }
    }
}
