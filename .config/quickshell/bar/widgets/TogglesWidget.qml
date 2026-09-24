import "../../services"
import "../../style"
import QtQuick

Item {
    id: root

    required property QuickPager pager

    signal expandRequested()

    implicitWidth: icon.implicitWidth + Style.widgets.padding * 2
    implicitHeight: Style.bar.height

    Text {
        id: icon

        anchors.centerIn: parent
        text: QuickToggles.anyOn ? "\u{F0B8D}" : "\u{F01D8}"
        color: Colors.icon.active
        font.family: Style.text.font
        font.pixelSize: Style.text.iconSize
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                root.expandRequested();
            else
                root.pager.toggleAt(root.pager.pageToggles, root);
        }
    }

}
