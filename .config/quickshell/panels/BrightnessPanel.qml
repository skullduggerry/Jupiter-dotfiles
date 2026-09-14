import "../services"
import "../style"
import QtQuick

Item {
    id: root

    readonly property bool wantsKeyboard: false
    readonly property int preferredHeight: Style.bar.padding * 2 + header.height + Style.bar.spacing + rows.implicitHeight

    Binding {
        target: Brightness
        property: "active"
        value: true
    }

    Text {
        id: header

        text: "Brightness"
        color: Colors.text.base
        font.family: Style.text.font
        font.pixelSize: Style.text.size

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

    }

    Column {
        id: rows

        spacing: Style.bar.spacing

        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            topMargin: Style.bar.spacing
        }

        Row {
            width: parent.width
            spacing: Style.widgets.spacing
            visible: Brightness.available

            Text {
                id: brightnessIcon

                width: Style.popup.rowIconWidth
                text: "󰃟"
                color: Colors.icon.active
                font.family: Style.text.font
                font.pixelSize: Style.text.iconSize
                anchors.verticalCenter: parent.verticalCenter
            }

            PanelSlider {
                width: parent.width - brightnessIcon.width - brightnessValue.width - Style.widgets.spacing * 2
                anchors.verticalCenter: parent.verticalCenter
                value: Brightness.fraction
                onMoved: (position) => {
                    return Brightness.setPercent(Math.round(position * 100));
                }
            }

            Text {
                id: brightnessValue

                width: Style.popup.rowIconWidth * 2
                horizontalAlignment: Text.AlignRight
                text: Math.round(Brightness.fraction * 100) + "%"
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
                anchors.verticalCenter: parent.verticalCenter
            }

        }

        Text {
            width: parent.width
            visible: !Brightness.available
            text: "No backlight found"
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }

    }

}
