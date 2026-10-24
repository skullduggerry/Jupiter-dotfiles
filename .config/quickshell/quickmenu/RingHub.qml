import "../icons"
import "../style"
import QtQuick
import QtQuick.Shapes

// The quick menu's centre, around (0, 0): Settings and the pencil while
// nothing is selected (`halves`), Done while the slots are being changed,
// otherwise the name and state of what is selected. Orbit's is a disc of its
// own (`framed`); Halo's is the middle of its disc, inside a hairline.
Item {
    id: root

    property bool framed: false
    property bool halves: true
    property bool editing: false
    // The half or the whole lit: "settings", "edit", "done" or "".
    property string lit: ""
    property string title: ""
    property string detail: ""
    property bool danger: false
    readonly property real radius: Style.quickMenu.centerRadius
    readonly property real half: Style.quickMenu.gap / 2
    readonly property real tint: root.radius - Style.quickMenu.inset
    readonly property string disc: `M 0,${-root.radius} A ${root.radius} ${root.radius} 0 1 1 0,${root.radius} A ${root.radius} ${root.radius} 0 1 1 0,${-root.radius} Z`
    readonly property string leftHalf: `M ${-root.half},${-root.tint} A ${root.tint} ${root.tint} 0 0 0 ${-root.half},${root.tint} Z`
    readonly property string rightHalf: `M ${root.half},${-root.tint} A ${root.tint} ${root.tint} 0 0 1 ${root.half},${root.tint} Z`
    readonly property string wholeTint: `M 0,${-root.tint} A ${root.tint} ${root.tint} 0 1 1 0,${root.tint} A ${root.tint} ${root.tint} 0 1 1 0,${-root.tint} Z`

    Shape {
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.framed ? Colors.base.surface : "transparent"
            strokeColor: Colors.base.border
            strokeWidth: Style.border.width

            PathSvg {
                path: root.disc
            }
        }

        ShapePath {
            fillColor: root.lit !== "" ? Colors.pill.selected : "transparent"
            strokeColor: "transparent"

            PathSvg {
                path: root.lit === "settings" ? root.leftHalf : root.lit === "edit" ? root.rightHalf : root.wholeTint
            }
        }
    }

    Row {
        visible: root.halves
        anchors.centerIn: parent
        spacing: Style.bar.padding * 2

        Icon {
            text: Icons.settings
            font.pixelSize: Style.widgets.iconSize
            color: root.lit === "settings" ? Colors.icon.active : Colors.text.muted
        }

        Icon {
            text: Icons.pencil
            font.pixelSize: Style.widgets.iconSize
            color: root.lit === "edit" ? Colors.icon.active : Colors.text.muted
        }
    }

    FontMetrics {
        id: small

        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
    }

    // The name over its state, both as wide as the disc is a line off its
    // middle; a word too long for that a little smaller.
    Column {
        visible: !root.halves
        anchors.centerIn: parent
        width: 2 * Math.sqrt(Math.pow(root.radius - Style.widgets.padding, 2) - Math.pow(small.height, 2))
        spacing: Style.widgets.spacing / 2

        Icon {
            visible: root.editing
            anchors.horizontalCenter: parent.horizontalCenter
            text: Icons.check
            font.pixelSize: Style.widgets.iconSize
        }

        Text {
            width: parent.width
            text: root.editing ? "Done" : root.title
            textFormat: Text.PlainText
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.size
            font.weight: Font.DemiBold
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: Style.quickMenu.leastTextSize
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Text {
            visible: !root.editing && root.detail !== ""
            width: parent.width
            height: Math.min(implicitHeight, small.height * 2)
            text: root.detail
            textFormat: Text.PlainText
            color: root.danger ? Colors.power.danger : Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: Style.quickMenu.leastTextSize
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }
}
