import "../panels"
import "../style"
import QtQuick

// A note under a list, and the action it leads to.
Item {
    id: root

    property string text: ""
    property string action: ""

    signal activated

    height: Style.popup.itemHeight

    Text {
        text: root.text
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
        elide: Text.ElideRight

        anchors {
            left: parent.left
            right: button.left
            rightMargin: Style.bar.spacing
            verticalCenter: parent.verticalCenter
        }
    }

    PillButton {
        id: button

        text: root.action
        action: true
        compact: true
        onClicked: root.activated()

        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
    }
}
