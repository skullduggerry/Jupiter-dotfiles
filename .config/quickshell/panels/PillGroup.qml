pragma ComponentBehavior: Bound

import "../style"
import QtQuick

// The design's two- and three-way switches: one pill per choice, the current
// one checked, after an optional upper-case label. Choices are {label, value},
// Off and On unless given. Given a width, the pills wrap to it, or share it
// out evenly with `fill`.
Flow {
    id: root

    property string label: ""
    property var choices: [
        {
            label: "Off",
            value: false
        },
        {
            label: "On",
            value: true
        }
    ]
    property var current
    property bool compact: false
    property bool fill: false

    signal picked(var value)

    spacing: root.compact ? Style.widgets.spacing : Style.bar.spacing

    Text {
        visible: root.label !== ""
        height: Style.popup.itemHeight
        verticalAlignment: Text.AlignVCenter
        text: root.label
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
        font.weight: Font.Medium
    }

    Repeater {
        model: root.choices

        delegate: PillButton {
            id: pill

            required property var modelData

            width: root.fill ? (root.width - root.spacing * (root.choices.length - 1)) / root.choices.length : pill.implicitWidth
            text: pill.modelData.label
            compact: root.compact
            checked: pill.modelData.value === root.current
            onClicked: root.picked(pill.modelData.value)
        }
    }
}
