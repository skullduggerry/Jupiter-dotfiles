pragma ComponentBehavior: Bound

import "../../icons"
import "../../panels"
import "../../services"
import "../../style"
import QtQuick
import Quickshell

// The shelf (services/Shelf): images, notes and files every device has, through
// Nextcloud. SUPER+X opens it here, SUPER+SHIFT+V pastes the clipboard onto it.
Item {
    id: root

    required property ShellScreen screen

    implicitWidth: icon.implicitWidth + Style.widgets.padding * 2
    implicitHeight: Style.bar.height

    Icon {
        id: icon

        anchors.centerIn: parent
        text: Icons.inbox
    }

    MouseArea {
        anchors.fill: parent
        onClicked: shelfPopup.visible = !shelfPopup.visible
    }

    Connections {
        function onToggleRequested() {
            shelfPopup.visible = !shelfPopup.visible;
        }

        target: Shelf
    }

    WidgetPopup {
        id: shelfPopup

        screen: root.screen
        anchorItem: root
        namespaceSuffix: "shelf-popup"
        popupWidth: Style.dropdown.width
        popupHeight: Math.max(Style.popup.minHeight, Math.min(Style.dropdown.maxHeight, Math.floor(panel.implicitHeight)))

        Loader {
            id: panel

            anchors.fill: parent
            active: shelfPopup.visible
            // Ready to type a note into.
            onLoaded: (panel.item as ShelfPanel).focusNote()

            sourceComponent: ShelfPanel {
                onPicked: shelfPopup.visible = false
            }
        }
    }
}
