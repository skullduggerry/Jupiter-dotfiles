import "../style"
import QtQuick

// A panel's chrome, the same in every surface that shows it: the padding, a
// header with the title and, at its right, `trailing`, a separator, then the
// content. A panel's implicitHeight is chromeHeight plus its content's, which
// text makes fractional: whatever sizes a panel by it rounds it down, or the
// bottom border blurs across two rows.
Item {
    id: root

    property string title: ""
    default property alias content: body.data
    property alias trailing: trailingRow.data
    readonly property int chromeHeight: Style.bar.padding * 2 + Style.popup.itemHeight + Style.border.width + Style.bar.spacing

    Item {
        id: header

        height: Style.popup.itemHeight

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Style.bar.padding
        }

        Text {
            text: root.title
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.size

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
        }

        Row {
            id: trailingRow

            spacing: Style.bar.spacing

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
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
