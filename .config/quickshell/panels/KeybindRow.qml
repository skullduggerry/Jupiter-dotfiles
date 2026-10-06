pragma ComponentBehavior: Bound

import "../services"
import "../style"
import QtQuick

// A bind of services/Keybinds as the Keybinds tab and the shortcuts overlay
// list it: its description, then its modifiers and keys as keycaps, `inset`
// from the row's edges.
Rectangle {
    id: root

    required property var modelData
    property int inset: 0

    radius: Style.popup.rowRadius
    color: "transparent"

    Text {
        text: root.modelData.description !== "" ? root.modelData.description : "No description"
        color: root.modelData.description !== "" ? Colors.text.base : Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.size
        elide: Text.ElideRight

        anchors {
            left: parent.left
            right: keys.left
            leftMargin: root.inset
            rightMargin: Style.bar.spacing
            verticalCenter: parent.verticalCenter
        }
    }

    Row {
        id: keys

        spacing: Style.widgets.spacing

        anchors {
            right: parent.right
            rightMargin: root.inset
            verticalCenter: parent.verticalCenter
        }

        Repeater {
            model: root.modelData.modifiers.concat([Keybinds.keysLabel(root.modelData.keys)])

            delegate: KeyCap {}
        }
    }
}
