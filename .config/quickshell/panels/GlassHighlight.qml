pragma ComponentBehavior: Bound

import "../style"
import QtQuick

// The finish of a specular variant's glass (acrylic's); nothing on other
// variants. Light along the upper edge, where the lens catches the light from
// above, fading down the surface. And where the glass is only part of its
// window (a dropdown in its full-screen layer), the rim Hyprland's lens would
// give it: Hyprland draws the lens around a whole window or layer only
// (.github/PROJECT_STRUCTURE.md, "Wallpaper"), so this draws bands that
// thicken toward the edge, and the light caught where they meet the clear
// middle. It bends nothing behind it. The glass's first child, so its content
// draws over it.
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

    // The rim's bands, from the edge in, each a little clearer.
    Repeater {
        model: root.lensed ? 0 : Style.blur.rimSteps

        delegate: Rectangle {
            id: band

            required property int index
            readonly property real inset: root.rim * band.index / Style.blur.rimSteps

            x: band.inset
            y: band.inset
            width: root.width - band.inset * 2
            height: root.height - band.inset * 2
            radius: Math.max(0, root.radius - band.inset)
            color: "transparent"
            border.width: Math.max(1, root.rim / Style.blur.rimSteps)
            border.color: Colors.withAlpha(Colors.base.lensBand, Colors.base.lensBand.a * (1 - band.index / Style.blur.rimSteps))
        }
    }

    Rectangle {
        visible: !root.lensed
        x: root.rim
        y: root.rim
        width: root.width - root.rim * 2
        height: root.height - root.rim * 2
        radius: Math.max(0, root.radius - root.rim)
        color: "transparent"
        border.width: Style.border.width
        border.color: Colors.base.caustic
    }
}
