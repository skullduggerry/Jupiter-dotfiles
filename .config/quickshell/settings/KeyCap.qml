import "../style"
import QtQuick

// A modifier or a key of a keybind, drawn as a keycap.
Rectangle {
    id: root

    required property string modelData

    width: Math.max(label.implicitWidth + Style.widgets.padding * 2, height)
    height: Style.settings.keyHeight
    radius: Style.popup.rowRadius
    color: Colors.base.hover
    border.width: Style.border.width
    border.color: Colors.base.border

    Text {
        id: label

        anchors.centerIn: parent
        text: root.modelData
        color: Colors.text.base
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
    }
}
