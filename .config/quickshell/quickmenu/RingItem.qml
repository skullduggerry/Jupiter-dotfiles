import "../icons"
import "../style"
import QtQuick

// What a slot or an item of Halo shows (QuickMenuItems.describe()): its
// glyph, on a filled disc while a toggle is on, in a meter for a level and
// plain otherwise, its letter on the glyph's corner; under it the label,
// which shrinks where its piece of the ring is narrower than it (`room`).
Item {
    id: root

    property var item: ({})
    property string key: ""
    property bool keyShown: false
    property real room: Style.quickMenu.slotWidth
    property bool selected: false
    property bool confirming: false
    readonly property bool toggle: root.item.kind === "toggle"
    readonly property bool level: root.item.kind === "level"
    readonly property bool dimmed: root.item.disabled === true

    width: Style.quickMenu.slotWidth
    height: body.implicitHeight

    Column {
        id: body

        width: parent.width
        spacing: Style.widgets.spacing

        Item {
            id: glyph

            anchors.horizontalCenter: parent.horizontalCenter
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

            // Off the glyph's corner, clear of its ink.
            KeyHint {
                x: glyph.width - width / 2 + Style.widgets.spacing
                y: -height / 2 - Style.widgets.spacing / 2
                key: root.key
                shown: root.keyShown
                selected: root.selected
            }
        }

        Text {
            id: label

            anchors.horizontalCenter: parent.horizontalCenter
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
    }
}
