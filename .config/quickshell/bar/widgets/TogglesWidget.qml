import "../../icons"
import "../../services"
import "../../style"
import QtQuick

Item {
    id: root

    required property QuickPager pager

    signal expandRequested

    implicitWidth: icon.implicitWidth + Style.widgets.padding * 2
    implicitHeight: Style.bar.height

    Icon {
        id: icon

        anchors.centerIn: parent
        text: QuickToggles.anyOn ? Icons.circleEllipsis : Icons.ellipsis
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.expandRequested();
            else
                root.pager.toggleAt(root.pager.pageToggles, root);
        }
    }
}
