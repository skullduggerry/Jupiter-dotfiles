import "../style"
import QtQuick

// A slot's or an item's letter, as a small keycap on its glyph's corner,
// which fades in once the menu shows its letters (`shown`).
Rectangle {
    id: root

    property string key: ""
    property bool shown: false
    property bool selected: false
    // The letter is measured this many times its size and scaled back: at
    // its own size the font's hinting rounds its ink to whole pixels.
    readonly property int measure: 16

    visible: root.key !== "" && root.opacity > 0
    opacity: root.shown ? 1 : 0
    width: Math.max(height, keyLabel.implicitWidth + Style.widgets.spacing * 2)
    height: Style.quickMenu.keyCapHeight
    radius: Style.popup.rowRadius
    color: Colors.base.base
    border.width: Style.border.width
    border.color: Colors.base.border

    Behavior on opacity {
        NumberAnimation {
            duration: Style.animation.slow
        }
    }

    // Centred on the letter itself, as CSS's `text-box: trim-both cap
    // alphabetic` does: across on its ink, and down on the band from the
    // baseline to the capitals' height. The font's line box, which centerIn
    // would centre, has more room on one side than the other.
    TextMetrics {
        id: ink

        font.family: keyLabel.font.family
        font.pixelSize: keyLabel.font.pixelSize * root.measure
        text: root.key
    }

    TextMetrics {
        id: capital

        font.family: keyLabel.font.family
        font.pixelSize: keyLabel.font.pixelSize * root.measure
        text: "H"
    }

    Text {
        id: keyLabel

        x: (root.width - ink.tightBoundingRect.width / root.measure) / 2 - ink.tightBoundingRect.x / root.measure
        y: (root.height - capital.tightBoundingRect.height / root.measure) / 2 - capital.tightBoundingRect.y / root.measure - keyLabel.baselineOffset
        text: root.key
        color: root.selected ? Colors.text.base : Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
    }
}
