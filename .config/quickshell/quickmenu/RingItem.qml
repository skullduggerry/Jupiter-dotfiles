import "../icons"
import "../style"
import QtQuick

// What a slot or an item of the quick menu shows (QuickMenuItems.describe()):
// its glyph, on a filled disc while a toggle is on, in a meter for a level and
// plain otherwise; under it the label, and a chevron after a category's or a
// list's, as after a submenu's in a menu. The label shrinks where its piece of
// the ring is narrower than it (`room`), and where it would run into its
// letter's cap. The letter is `keyAt` from its middle, further in along the
// radius.
Item {
    id: root

    property var item: ({})
    property string key: ""
    property point keyAt: Qt.point(0, 0)
    property real room: Style.quickMenu.slotWidth
    property bool selected: false
    property bool confirming: false
    readonly property bool toggle: root.item.kind === "toggle"
    readonly property bool level: root.item.kind === "level"
    readonly property bool dimmed: root.item.disabled === true
    // How wide the label can be before it meets the cap, where the two are
    // level (on the pieces at the sides, the cap is beside the label's end;
    // one that only brushes its row does not count), and no narrower than the
    // centre's text may shrink to.
    readonly property real clearance: {
        const top = body.y + labelRow.y;
        const shared = Math.min(top + labelRow.height, keyCap.y + keyCap.height) - Math.max(top, keyCap.y);
        if (!keyCap.visible || shared <= Style.widgets.spacing)
            return Infinity;

        const least = labelRow.implicitWidth * Style.quickMenu.leastTextSize / Style.text.smallSize;
        return Math.max(least, 2 * (Math.abs(keyCap.x + keyCap.width / 2 - root.width / 2) - keyCap.width / 2 - Style.widgets.spacing));
    }

    width: Style.quickMenu.slotWidth
    height: body.implicitHeight

    Column {
        id: body

        width: parent.width
        spacing: Style.widgets.spacing

        Item {
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
        }

        Row {
            id: labelRow

            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.widgets.spacing / 2
            scale: Math.min(1, Math.min(root.room, root.clearance) / labelRow.implicitWidth)

            Text {
                id: label

                width: Math.min(implicitWidth, root.width - (chevron.visible ? chevron.implicitWidth + parent.spacing : 0))
                // Asked again, by its name: the centre says what to do.
                text: (root.item.short ?? "") + (root.confirming ? "?" : "")
                // Muted text fails WCAG AA over a bright wallpaper's glass.
                color: root.confirming && root.item.danger === true ? Colors.power.danger : root.dimmed ? Colors.icon.disabled : Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Icon {
                id: chevron

                anchors.verticalCenter: label.verticalCenter
                visible: root.item.kind === "category" || root.item.kind === "list"
                text: Icons.chevronRight
                font.pixelSize: Style.text.smallSize
                color: label.color
            }
        }
    }

    Rectangle {
        id: keyCap

        // The letter is measured this many times its size and scaled back:
        // at its own size the font's hinting rounds its ink to whole pixels.
        readonly property int measure: 16

        visible: root.key !== ""
        x: root.width / 2 + root.keyAt.x - width / 2
        y: root.height / 2 + root.keyAt.y - height / 2
        width: Math.max(height, keyLabel.implicitWidth + Style.widgets.spacing * 2)
        height: Style.quickMenu.keyCapHeight
        radius: Style.popup.rowRadius
        color: Colors.base.base
        border.width: Style.border.width
        border.color: Colors.base.border

        // Centred on the letter itself, as CSS's `text-box: trim-both cap
        // alphabetic` does: across on its ink, and down on the band from the
        // baseline to the capitals' height. The font's line box, which
        // centerIn would centre, has more room on one side than the other.
        TextMetrics {
            id: ink

            font.family: keyLabel.font.family
            font.pixelSize: keyLabel.font.pixelSize * keyCap.measure
            text: root.key
        }

        TextMetrics {
            id: capital

            font.family: keyLabel.font.family
            font.pixelSize: keyLabel.font.pixelSize * keyCap.measure
            text: "H"
        }

        Text {
            id: keyLabel

            x: (keyCap.width - ink.tightBoundingRect.width / keyCap.measure) / 2 - ink.tightBoundingRect.x / keyCap.measure
            y: (keyCap.height - capital.tightBoundingRect.height / keyCap.measure) / 2 - capital.tightBoundingRect.y / keyCap.measure - keyLabel.baselineOffset
            text: root.key
            color: root.selected ? Colors.text.base : Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
        }
    }
}
