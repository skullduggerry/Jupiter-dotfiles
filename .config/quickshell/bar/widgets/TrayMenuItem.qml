// bar/widgets/TrayMenuItem.qml
import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../style"

Item {
    id: root

    required property QsMenuEntry modelData

    signal activated()

    readonly property bool checkable: root.modelData.buttonType !== QsMenuButtonType.None
    readonly property bool checked: root.modelData.checkState === Qt.Checked

    readonly property string checkGlyph: {
        if (root.modelData.buttonType === QsMenuButtonType.RadioButton)
            return root.checked ? "" : ""
        return root.checked ? "" : ""
    }

    height: root.modelData.isSeparator ? Style.bar.spacing : Style.popup.itemHeight

    Rectangle {
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        visible: root.modelData.isSeparator
        height: Style.border.width
        color: Colors.base.border
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.modelData.isSeparator
        radius: Style.popup.rowRadius
        color: area.containsMouse ? Colors.base.hover : "transparent"

        Item {
            id: lead
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            width: Style.popup.rowIconWidth
            height: lead.width

            IconImage {
                anchors.fill: parent
                visible: !root.checkable && root.modelData.icon !== ""
                implicitSize: Style.popup.rowIconWidth
                source: root.modelData.icon
            }

            Text {
                anchors.centerIn: parent
                visible: root.checkable
                text: root.checkGlyph
                color: root.checked ? Colors.menu.checked : Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
            }
        }

        Text {
            anchors {
                left: lead.right
                leftMargin: Style.widgets.spacing
                right: chevron.left
                rightMargin: Style.widgets.spacing
                verticalCenter: parent.verticalCenter
            }
            text: root.modelData.text
            color: root.modelData.enabled ? Colors.text.base : Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
            elide: Text.ElideRight
        }

        Text {
            id: chevron
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            visible: root.modelData.hasChildren
            width: chevron.visible ? Style.popup.rowIconWidth : 0
            text: ""
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            horizontalAlignment: Text.AlignRight
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
