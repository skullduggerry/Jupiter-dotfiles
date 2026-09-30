import "../style"
import QtQuick
import QtQuick.Shapes

// A value from 0 to 1 as a ring filling clockwise from the top, over a faint
// track: the bar's usage meters.
Item {
    id: root

    property real value: 0
    property color color: Colors.icon.active
    readonly property real radius: (Math.min(root.width, root.height) - Style.usage.ringWidth) / 2

    implicitWidth: Style.text.iconSize
    implicitHeight: Style.text.iconSize

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Colors.icon.track
            strokeWidth: Style.usage.ringWidth
            fillColor: "transparent"

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.radius
                radiusY: root.radius
                startAngle: 0
                sweepAngle: 360
            }
        }

        ShapePath {
            strokeColor: root.color
            strokeWidth: Style.usage.ringWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.radius
                radiusY: root.radius
                startAngle: -90
                sweepAngle: 360 * Math.max(0, Math.min(1, root.value))
            }
        }
    }
}
