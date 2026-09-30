import "../icons"
import "../style"
import QtQuick

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool checked: false

    signal activated
    // A right click, for a tile with more behind it (Clipboard's history,
    // Caffeine's length).
    signal secondaryActivated

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

            Icon {
                anchors.centerIn: parent
                text: root.icon
                color: root.checked ? Colors.text.inverted : Colors.icon.active
            }

            Behavior on color {
                ColorAnimation {
                    duration: Style.animation.normal
                }
            }
        }

        // Three to a row, "Do Not Disturb" needs two lines.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.width - Style.widgets.padding * 2
            text: root.label
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.secondaryActivated();
            else
                root.activated();
        }
    }
}
