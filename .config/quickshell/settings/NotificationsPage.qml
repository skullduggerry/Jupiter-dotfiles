import "../panels"
import "../services"
import "../style"
import QtQuick

// Do Not Disturb, and the notification centre itself. While it is shown,
// toasts give way to it, as they do to the bell's.
Item {
    id: root

    Section {
        id: dnd

        title: "DO NOT DISTURB"

        anchors {
            top: parent.top
            left: parent.left
            leftMargin: Style.settings.padding
        }

        PillGroup {
            current: NotificationService.doNotDisturb
            onPicked: on => {
                NotificationService.doNotDisturb = on;
            }
        }
    }

    PanelCard {
        preferredHeight: centre.implicitHeight

        anchors {
            top: dnd.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            topMargin: Style.settings.spacing
        }

        NotificationPanel {
            id: centre

            anchors.fill: parent
        }
    }
}
