import "../services"
import "../style"
import QtQuick
import QtQuick.Shapes

// A panel out beside the quick menu, its box bent around the ring: the edge
// toward the menu keeps the arc's distance from the centre, the far edge the
// panel's width from that, and every row starts where place() says, so the
// rows follow the curve, as they scroll too. Drawn around the menu's centre
// on `side` (1 right, -1 left), as tall as its content asks, up to
// `panelSpan` degrees round either way of level, as near `level` (a height
// from the centre) as that leaves room for. Inside, as in a PanelFrame: a
// header with `leading` (a search field), the title and `trailing`, a
// separator, then its children.
Item {
    id: root

    required property int side
    property real level: 0
    property string title: ""
    property alias leading: leadingRow.data
    property alias trailing: trailingRow.data
    default property alias content: body.data
    // What the children would take; past what fits, they scroll.
    property real contentHeight: 0
    // The containmentMask of whatever fills the body and takes input: the
    // body's box reaches over the ring, which keeps its clicks there.
    readonly property QtObject bodyMask: QtObject {
        function contains(point: point): bool {
            return root.covers(body.x + point.x, body.y + point.y);
        }
    }
    readonly property real radius: Style.quickMenu.arcInner
    readonly property real rowWidth: Style.quickMenu.panelWidth - Style.bar.padding * 2
    readonly property real reach: root.radius * Math.sin(Style.quickMenu.panelSpan * Math.PI / 180)
    // PanelFrame's chrome over the content, as far as the span allows.
    readonly property real panelHeight: Math.min(root.reach * 2, Style.bar.padding * 2 + Style.popup.itemHeight + Style.border.width + Style.bar.spacing + root.contentHeight)
    readonly property real upper: Math.max(-root.reach, Math.min(root.reach - root.panelHeight, root.level - root.panelHeight / 2))
    readonly property real lower: root.upper + root.panelHeight
    property real reveal

    // How far across from the centre the curve is at a height.
    function curve(y: real): real {
        return Math.sqrt(Math.max(0, root.radius * root.radius - y * y));
    }

    // Where a row `height` high starts across, at `top` from the centre's
    // level: its middle keeps the padding from the curve.
    function rowX(top: real, height: real): real {
        const edge = root.curve(top + height / 2) + Style.bar.padding;
        return root.side > 0 ? edge : -edge - root.rowWidth;
    }

    // The same for a child, `top` down the body (less what it has scrolled),
    // in the body's coordinates.
    function place(top: real, height: real): real {
        return root.rowX(body.y + top, height) - body.x;
    }

    // Whether a point around the menu's centre is on the panel.
    function covers(x: real, y: real): bool {
        const across = x * root.side - root.curve(y);
        return y >= root.upper && y <= root.lower && across >= 0 && across <= Style.quickMenu.panelWidth;
    }

    opacity: root.reveal
    scale: Style.quickMenu.calmFrom + (1 - Style.quickMenu.calmFrom) * root.reveal

    NumberAnimation on reveal {
        from: 0
        to: 1
        duration: QuickMenu.playful ? Style.quickMenu.spring : Style.animation.normal
        easing.type: QuickMenu.playful ? Easing.OutBack : Easing.OutCubic
        easing.overshoot: Style.quickMenu.overshoot
    }

    Shape {
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Colors.base.surface
            strokeColor: Colors.base.border
            strokeWidth: Style.border.width

            PathSvg {
                path: {
                    const r = root.radius;
                    const across = root.side * Style.quickMenu.panelWidth;
                    const upperX = root.side * root.curve(root.upper);
                    const lowerX = root.side * root.curve(root.lower);
                    const out = root.side > 0 ? 1 : 0;
                    return `M ${upperX},${root.upper} L ${upperX + across},${root.upper} A ${r} ${r} 0 0 ${out} ${lowerX + across},${root.lower} L ${lowerX},${root.lower} A ${r} ${r} 0 0 ${1 - out} ${upperX},${root.upper} Z`;
                }
            }
        }
    }

    Item {
        id: header

        x: root.rowX(header.y, header.height)
        y: root.upper + Style.bar.padding
        width: root.rowWidth
        height: Style.popup.itemHeight

        Row {
            id: leadingRow

            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.widgets.spacing
        }

        Text {
            anchors.left: leadingRow.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }

        Row {
            id: trailingRow

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.bar.spacing
        }
    }

    Rectangle {
        id: separator

        x: root.rowX(separator.y, separator.height)
        y: header.y + header.height
        width: root.rowWidth
        height: Style.border.width
        color: Colors.base.border
    }

    // As wide as the rows reach, wherever they are.
    Item {
        id: body

        readonly property real deepest: root.curve(Math.max(root.upper, Math.min(0, root.lower)))
        readonly property real shallowest: Math.min(root.curve(root.upper), root.curve(root.lower))

        x: root.side > 0 ? body.shallowest + Style.bar.padding : -body.deepest - Style.bar.padding - root.rowWidth
        y: separator.y + separator.height + Style.bar.spacing
        width: body.deepest - body.shallowest + root.rowWidth
        height: root.lower - Style.bar.padding - body.y
    }
}
