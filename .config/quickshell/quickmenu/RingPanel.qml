import "../services"
import "../panels"
import "../style"
import QtQuick

// A panel out beside the quick menu, in the dropdowns' box: around the
// menu's centre on `side` (1 right, -1 left), its edge toward the menu where
// a category's arc starts, as tall as its content asks up to `panelHeight`,
// as near `level` (a height from the centre) as the menu's own height
// leaves room for. Inside, as in a PanelFrame: a header with `leading` (a
// search field), the title and `trailing`, a separator, then its children.
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
    readonly property real rowWidth: Style.quickMenu.panelWidth - Style.bar.padding * 2
    readonly property real chromeHeight: Style.bar.padding * 2 + Style.popup.itemHeight + Style.border.width + Style.bar.spacing
    readonly property real panelHeight: Math.min(Style.quickMenu.panelHeight, root.chromeHeight + root.contentHeight)
    readonly property real upper: Math.max(-Style.quickMenu.arcOuter, Math.min(Style.quickMenu.arcOuter - root.panelHeight, root.level - root.panelHeight / 2))
    property real reveal

    // Whether a point around the menu's centre is on the panel.
    function covers(x: real, y: real): bool {
        const across = x * root.side - Style.quickMenu.arcInner;
        return y >= root.upper && y <= root.upper + root.panelHeight && across >= 0 && across <= Style.quickMenu.panelWidth;
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

    Rectangle {
        x: root.side > 0 ? Style.quickMenu.arcInner : -Style.quickMenu.arcInner - width
        y: root.upper
        width: Style.quickMenu.panelWidth
        height: root.panelHeight
        radius: Style.bar.radius
        color: Colors.base.surface
        border.width: Style.border.width
        border.color: Colors.base.edge

        GlassHighlight {}

        Item {
            id: header

            height: Style.popup.itemHeight

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: Style.bar.padding
            }

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

            height: Style.border.width
            color: Colors.base.border

            anchors {
                top: header.bottom
                left: header.left
                right: header.right
            }
        }

        Item {
            id: body

            anchors {
                top: separator.bottom
                bottom: parent.bottom
                left: header.left
                right: header.right
                topMargin: Style.bar.spacing
                bottomMargin: Style.bar.padding
            }
        }
    }
}
