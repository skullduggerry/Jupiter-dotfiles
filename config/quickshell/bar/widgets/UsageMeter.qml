// bar/widgets/UsageMeter.qml
//
// One load readout as a single glyph: a circle that fills as the value rises,
// and nothing else. The same idea as the brightness ramp in the waybar config
// this shell replaces — `"format": "{icon}"` with a nine-step ramp and no
// text — which is the most a status bar needs to say about a number nobody
// reads precisely.
//
// The ramp is nf-md-circle-outline followed by nf-md-circle-slice-1..8, so
// step 0 is genuinely empty rather than already an eighth full. Brightness
// uses the ramp from the waybar config verbatim, so the two stay
// distinguishable side by side: that one fills like a moon, this one like a
// pie.
import QtQuick
import "../../style"

Item {
    id: root

    // 0.0-1.0.
    required property real value

    readonly property var ramp: ["󰄰", "󰪞", "󰪟", "󰪠", "󰪡", "󰪢", "󰪣", "󰪤", "󰪥"]

    implicitWidth: Style.text.iconSize + Style.widgets.spacing
    implicitHeight: Style.bar.height

    Text {
        anchors.centerIn: parent
        text: root.ramp[Math.round(Math.max(0, Math.min(1, root.value)) * (root.ramp.length - 1))]
        color: root.value > Style.usage.warnAbove ? Colors.usage.warn : Colors.usage.normal
        font.family: Style.text.font
        font.pixelSize: Style.text.iconSize
    }
}
