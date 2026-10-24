import "../icons"
import "../style"
import QtQuick
import QtQuick.Shapes

// A slot or an item as Orbit draws it (QuickMenuItems.describe()): a round
// button with the panels' glass and border and the glyph on it, filled while
// a toggle is on, a meter inside its rim for a level, and its letter on its
// corner. Selected, it grows and is ringed in the accent, as a picked
// workspace or display is outlined; it is dashed while the slots are being
// changed, and for an empty slot.
Item {
    id: root

    property var item: ({})
    property real size: Style.quickMenu.buttonSize
    property bool selected: false
    property bool dashed: false
    property bool confirming: false
    property string key: ""
    property bool keyShown: false
    readonly property bool empty: root.item.kind === "empty"
    readonly property bool on: root.item.kind === "toggle" && root.item.on === true
    readonly property bool dimmed: root.item.disabled === true

    width: root.size
    height: root.size
    scale: root.selected ? Style.quickMenu.selectedScale : 1

    Behavior on scale {
        NumberAnimation {
            duration: Style.animation.normal
            easing.type: Easing.OutCubic
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.empty ? "transparent" : root.on ? Colors.icon.active : root.selected ? Qt.tint(Colors.base.surface, Colors.pill.selected) : Colors.base.surface
            strokeColor: root.confirming && root.item.danger === true ? Colors.power.danger : root.selected ? Colors.accent.primary : Colors.base.border
            strokeWidth: root.selected ? Style.quickMenu.connectorWidth : Style.border.width
            strokeStyle: root.dashed || root.empty ? ShapePath.DashLine : ShapePath.SolidLine
            dashPattern: Style.quickMenu.dash

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: (root.size - Style.border.width) / 2
                radiusY: (root.size - Style.border.width) / 2
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    RingIcon {
        anchors.centerIn: parent
        visible: root.item.kind === "level"
        width: root.size - Style.widgets.padding
        height: root.size - Style.widgets.padding
        value: root.item.level ?? 0
    }

    Icon {
        anchors.centerIn: parent
        text: root.item.icon ?? ""
        font.pixelSize: Style.widgets.iconSize
        color: root.dimmed ? Colors.icon.disabled : root.on ? Colors.text.inverted : Colors.icon.active
    }

    // On the rim, up and to the right.
    KeyHint {
        x: root.size / 2 * (1 + Math.SQRT1_2) - width / 2
        y: root.size / 2 * (1 - Math.SQRT1_2) - height / 2
        key: root.key
        shown: root.keyShown
        selected: root.selected
    }
}
