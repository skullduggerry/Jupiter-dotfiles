import "../style"
import QtQuick
import QtQuick.Shapes

// A piece of the quick menu's ring or arc around (0, 0): the band from `inner`
// to `outer` between the angles `from` and `to` (degrees clockwise from the
// top), short of its neighbours by Style.quickMenu.gap. Glass with the
// shell's border, lit while selected, stronger while its category is out,
// and dashed while the slots are being changed and for an empty slot.
Shape {
    id: root

    property real inner: 0
    property real outer: 0
    property real from: 0
    property real to: 0
    property bool selected: false
    property bool raised: false
    property bool dashed: false
    property bool empty: false
    readonly property string path: {
        const point = (radius, angle) => {
            const turn = (angle - 90) * Math.PI / 180;
            return (radius * Math.cos(turn)).toFixed(2) + "," + (radius * Math.sin(turn)).toFixed(2);
        };
        const outerInset = Style.quickMenu.gap / 2 / root.outer * 180 / Math.PI;
        const innerInset = Style.quickMenu.gap / 2 / root.inner * 180 / Math.PI;
        const large = root.to - root.from > 180 ? 1 : 0;
        return `M ${point(root.outer, root.from + outerInset)} A ${root.outer} ${root.outer} 0 ${large} 1 ${point(root.outer, root.to - outerInset)} L ${point(root.inner, root.to - innerInset)} A ${root.inner} ${root.inner} 0 ${large} 0 ${point(root.inner, root.from + innerInset)} Z`;
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.empty ? "transparent" : Colors.base.surface
        strokeColor: Colors.base.border
        strokeWidth: Style.border.width
        strokeStyle: root.dashed || root.empty ? ShapePath.DashLine : ShapePath.SolidLine
        dashPattern: Style.quickMenu.dash

        PathSvg {
            path: root.path
        }
    }

    ShapePath {
        fillColor: root.selected ? Colors.pill.selected : root.raised ? Colors.base.hover : "transparent"
        strokeColor: "transparent"

        PathSvg {
            path: root.path
        }
    }
}
