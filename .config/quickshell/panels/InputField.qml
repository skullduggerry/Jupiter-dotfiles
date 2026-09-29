import "../style"
import QtQuick

Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property string icon: ""
    readonly property bool editing: input.activeFocus

    signal accepted

    function focusInput() {
        input.forceActiveFocus();
    }

    implicitHeight: Style.popup.itemHeight
    radius: Style.popup.rowRadius
    color: Colors.base.hover
    border.width: Style.border.width
    border.color: input.activeFocus ? Colors.icon.active : Colors.base.border

    // Below the input in the child order so it only picks up clicks on the
    // padding; the TextInput takes its own focus and keeps mouse selection.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onClicked: input.forceActiveFocus()
    }

    Text {
        id: fieldIcon

        text: root.icon
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.iconSize

        anchors {
            left: parent.left
            leftMargin: Style.widgets.padding
            verticalCenter: parent.verticalCenter
        }
    }

    TextInput {
        id: input

        color: Colors.text.base
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
        clip: true
        selectByMouse: true
        onAccepted: root.accepted()

        anchors {
            left: fieldIcon.right
            right: parent.right
            leftMargin: Style.widgets.spacing
            rightMargin: Style.widgets.padding
            verticalCenter: parent.verticalCenter
        }

        Text {
            anchors.fill: parent
            visible: input.text === ""
            text: root.placeholder
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Style.animation.normal
        }
    }
}
