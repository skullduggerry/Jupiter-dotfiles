import "../style"
import QtQuick
import QtQuick.Shapes

// A piece of a band around (0, 0), as Halo draws its tints, its arc and the
// slots being changed: from `inner` to `outer` between the angles `from` and
// `to` (degrees clockwise from the top), its two ends `edge` inside those
// angles and parallel to them, its corners rounded by `corner`.
Shape {
    id: root

    property real inner: 0
    property real outer: 0
    property real from: 0
    property real to: 0
    property real edge: 0
    property real corner: 0
    property color fillColor: "transparent"
    property color strokeColor: "transparent"
    property bool dashed: false
    readonly property string path: {
        const point = (radius, angle) => {
            const turn = (angle - 90) * Math.PI / 180;
            return (radius * Math.cos(turn)).toFixed(2) + "," + (radius * Math.sin(turn)).toFixed(2);
        };
        const degrees = radians => radians * 180 / Math.PI;
        // How far round an end is at a radius, kept `edge` from the angle's
        // own radius, and how far round the corner's curve starts from it.
        const end = radius => degrees(Math.asin(Math.min(1, root.edge / radius)));
        const along = radius => degrees(root.corner / radius);
        const c = Math.min(root.corner, (root.outer - root.inner) / 2);
        const a = root.from;
        const b = root.to;
        const large = b - a > 180 ? 1 : 0;
        return `M ${point(root.outer, a + end(root.outer) + along(root.outer))}` + ` A ${root.outer} ${root.outer} 0 ${large} 1 ${point(root.outer, b - end(root.outer) - along(root.outer))}` + ` Q ${point(root.outer, b - end(root.outer))} ${point(root.outer - c, b - end(root.outer - c))}` + ` L ${point(root.inner + c, b - end(root.inner + c))}` + ` Q ${point(root.inner, b - end(root.inner))} ${point(root.inner, b - end(root.inner) - along(root.inner))}` + ` A ${root.inner} ${root.inner} 0 ${large} 0 ${point(root.inner, a + end(root.inner) + along(root.inner))}` + ` Q ${point(root.inner, a + end(root.inner))} ${point(root.inner + c, a + end(root.inner + c))}` + ` L ${point(root.outer - c, a + end(root.outer - c))}` + ` Q ${point(root.outer, a + end(root.outer))} ${point(root.outer, a + end(root.outer) + along(root.outer))} Z`;
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.fillColor
        strokeColor: root.strokeColor
        strokeWidth: Style.border.width
        strokeStyle: root.dashed ? ShapePath.DashLine : ShapePath.SolidLine
        dashPattern: Style.quickMenu.dash

        PathSvg {
            path: root.path
        }
    }
}
