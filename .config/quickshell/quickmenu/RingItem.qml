import "../icons"
import "../style"
import QtQuick

// What a slot or an item of Halo shows (QuickMenuItems.describe()), along
// its radius from the hub out: its letter, its glyph (on a filled disc while
// a toggle is on, in a meter for a level, plain otherwise), then its label,
// above the glyph on the ring's upper half and under it on the lower
// (`labelAbove`), so the letter never meets it. The label shrinks where its
// piece of the ring is narrower than it (`room`); without `showLabel`, the
// glyph is alone.
Item {
    id: root

    property var item: ({})
    // Where it sits round the ring, in degrees clockwise from the top: its
    // letter goes toward the centre from there.
    property real angle: 0
    property bool showLabel: true
    property bool labelAbove: false
    property string key: ""
    property bool keyShown: false
    property real room: Style.quickMenu.slotWidth
    property bool selected: false
    property bool confirming: false
    readonly property bool toggle: root.item.kind === "toggle"
    readonly property bool level: root.item.kind === "level"
    readonly property bool dimmed: root.item.disabled === true
    readonly property real turn: root.angle * Math.PI / 180

    width: Style.quickMenu.slotWidth
    height: glyph.height + (root.showLabel ? Style.widgets.spacing + label.height : 0)

    Item {
        id: glyph

        x: (root.width - glyph.width) / 2
        y: root.showLabel && root.labelAbove ? label.height + Style.widgets.spacing : 0
        width: Style.toggles.badgeSize
        height: Style.toggles.badgeSize

        Rectangle {
            anchors.fill: parent
            visible: root.toggle
            radius: width / 2
            color: root.item.on === true ? Colors.icon.active : Colors.base.hover
        }

        RingIcon {
            anchors.fill: parent
            visible: root.level
            value: root.item.level ?? 0
        }

        Icon {
            anchors.centerIn: parent
            text: root.item.icon ?? ""
            font.pixelSize: root.toggle || root.level ? Style.text.iconSize : Style.widgets.iconSize
            color: root.dimmed ? Colors.icon.disabled : root.toggle && root.item.on === true ? Colors.text.inverted : Colors.icon.active
        }
    }

    Text {
        id: label

        visible: root.showLabel
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.labelAbove ? 0 : glyph.height + Style.widgets.spacing
        width: Math.min(implicitWidth, root.width)
        scale: Math.min(1, root.room / label.width)
        // Asked again, by its name: the centre says what to do.
        text: (root.item.short ?? "") + (root.confirming ? "?" : "")
        textFormat: Text.PlainText
        // Muted text fails WCAG AA over a bright wallpaper's glass.
        color: root.confirming && root.item.danger === true ? Colors.power.danger : root.dimmed ? Colors.icon.disabled : Colors.text.base
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
    }

    // Toward the centre from the glyph's middle, just clear of its edge.
    KeyHint {
        readonly property real reach: glyph.width / 2 + Style.widgets.spacing / 2 + Math.max(width, height) / 2

        x: glyph.x + glyph.width / 2 - Math.sin(root.turn) * reach - width / 2
        y: glyph.y + glyph.height / 2 + Math.cos(root.turn) * reach - height / 2
        key: root.key
        shown: root.keyShown
        selected: root.selected
    }
}
