import "../../icons"
import "../../style"
import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    required property QsMenuEntry modelData
    readonly property bool checkable: root.modelData.buttonType !== QsMenuButtonType.None
    readonly property bool checked: root.modelData.checkState === Qt.Checked
    readonly property string checkGlyph: {
        if (root.modelData.buttonType === QsMenuButtonType.RadioButton)
            return root.checked ? Icons.circleDot : Icons.circle;

        return root.checked ? Icons.squareCheck : Icons.square;
    }

    signal activated

    height: root.modelData.isSeparator ? Style.bar.spacing : Style.popup.itemHeight

    Rectangle {
        visible: root.modelData.isSeparator
        height: Style.border.width
        color: Colors.base.border

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.modelData.isSeparator
        radius: Style.popup.rowRadius
        color: area.containsMouse ? Colors.base.hover : "transparent"

        Item {
            id: lead

            width: Style.popup.rowIconWidth
            height: lead.width

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }

            IconImage {
                anchors.fill: parent
                visible: !root.checkable && root.modelData.icon !== ""
                implicitSize: Style.popup.rowIconWidth
                source: root.modelData.icon
            }

            Icon {
                anchors.centerIn: parent
                visible: root.checkable
                text: root.checkGlyph
                color: root.checked ? Colors.menu.checked : Colors.text.muted
                font.pixelSize: Style.text.smallSize
            }
        }

        Text {
            text: root.modelData.text
            textFormat: Text.PlainText
            color: root.modelData.enabled ? Colors.text.base : Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
            elide: Text.ElideRight

            anchors {
                left: lead.right
                leftMargin: Style.widgets.spacing
                right: chevron.left
                rightMargin: Style.widgets.spacing
                verticalCenter: parent.verticalCenter
            }
        }

        Icon {
            id: chevron

            visible: root.modelData.hasChildren
            width: chevron.visible ? Style.popup.rowIconWidth : 0
            text: Icons.chevronRight
            color: Colors.text.muted
            font.pixelSize: Style.text.smallSize
            horizontalAlignment: Text.AlignRight

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: area

            anchors.fill: parent
            hoverEnabled: true
            enabled: root.modelData.enabled
            onClicked: root.activated()
        }
    }
}
