import "../style"
import QtQuick

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool checked: false

    signal activated()

    implicitHeight: Style.toggles.tileHeight
    radius: Style.popup.rowRadius
    color: area.containsMouse ? Colors.base.hover : "transparent"
    border.width: Style.border.width
    border.color: Colors.base.border

    Column {
        anchors.centerIn: parent
        spacing: Style.widgets.spacing

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Style.toggles.badgeSize
            height: Style.toggles.badgeSize
            radius: width / 2
            color: root.checked ? Colors.icon.active : Colors.base.hover

            Text {
                anchors.centerIn: parent
                text: root.icon
                color: root.checked ? Colors.text.inverted : Colors.icon.active
                font.family: Style.text.font
                font.pixelSize: Style.text.iconSize
            }

            Behavior on color {
                ColorAnimation {
                    duration: Style.animation.normal
                }

            }

        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(implicitWidth, root.width - Style.widgets.padding * 2)
            text: root.label
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            elide: Text.ElideRight
        }

    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.activated()
    }

}
