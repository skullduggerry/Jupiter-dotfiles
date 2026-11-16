pragma ComponentBehavior: Bound

import "../style"
import QtQuick

// The finish of a specular variant's glass (acrylic's); nothing on other
// variants. Light along the upper edge, where the lens catches the light from
// above, fading down the surface. And where the glass is only part of its
// window (a dropdown in its full-screen layer), the rim Hyprland's lens would
// give it: Hyprland draws the lens around a whole window or layer only, so
// this draws the glass thickening toward its edge, in bands thin enough to
// read as one slope: the
// rim runs under the content, where a step or a line would cross the text.
// It bends nothing behind it. The glass's first child, so its content draws
// over it.
Item {
    id: root

    // The glass's own corner radius, which this follows inside its border.
    property real outerRadius: Style.bar.radius
    // Whether Hyprland's own lens frames this glass, its window or layer
    // being exactly the glass (the bar, a lone toast, a ChoiceField's list):
    // then only the light is drawn.
    property bool lensed: false
    readonly property real radius: Math.max(0, root.outerRadius - Style.border.width)
    readonly property real rim: Math.min(Style.blur.rim, Math.min(root.width, root.height) * Style.blur.rimShare)
    readonly property int bands: Math.ceil(root.rim / Style.blur.rimBand)

    anchors.fill: parent
    anchors.margins: Style.border.width
    visible: Colors.base.specular

    Rectangle {
        anchors.fill: parent
        radius: root.radius

        gradient: Gradient {
            GradientStop {
                position: 0
                color: Colors.base.highlight
            }
            GradientStop {
                position: Style.blur.highlightFade
                color: "transparent"
            }
        }
    }

    // The rim's bands, from the edge in, each a little clearer: steeply at
    // the edge and levelling out into the clear middle, as a lens does.
    Repeater {
        model: root.lensed ? 0 : root.bands

        delegate: Rectangle {
            id: band

            required property int index
            readonly property real inset: root.rim * band.index / root.bands

            x: band.inset
            y: band.inset
            width: root.width - band.inset * 2
            height: root.height - band.inset * 2
            radius: Math.max(0, root.radius - band.inset)
            color: "transparent"
            border.width: Math.max(1, root.rim / root.bands)
            border.color: Colors.withAlpha(Colors.base.lensBand, Colors.base.lensBand.a * Math.pow(1 - band.index / root.bands, 2))
        }
    }
}
