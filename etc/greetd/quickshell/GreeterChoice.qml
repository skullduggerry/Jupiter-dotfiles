import QtQuick
import "style"

Rectangle {
    id: root

    required property string label
    required property bool selected

    signal chosen

    implicitWidth: choiceLabel.implicitWidth + Style.bar.padding * 2
    implicitHeight: Style.popup.itemHeight
    radius: Style.lock.fieldRadius
    color: root.selected ? Colors.lock.field : "transparent"
    border.width: Style.border.width
    border.color: root.selected ? Colors.lock.busy : Colors.lock.fieldBorder

    Text {
        id: choiceLabel

        anchors.centerIn: parent
        text: root.label
        textFormat: Text.PlainText
        color: root.selected ? Colors.text.base : Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.chosen()
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Style.animation.normal
        }
    }
}
