import "../../panels"
import "../../services"
import "../../style"
import QtQuick
import Quickshell

Item {
    id: root

    required property ShellScreen screen

    implicitWidth: meters.implicitWidth
    implicitHeight: Style.bar.height

    Binding {
        target: SystemUsage
        property: "active"
        value: true
    }

    Row {
        id: meters

        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.widgets.spacing

        UsageMeter {
            value: SystemUsage.cpu
        }

        UsageMeter {
            value: SystemUsage.memory
        }

    }

    MouseArea {
        anchors.fill: parent
        onClicked: usagePopup.visible = !usagePopup.visible
    }

    WidgetPopup {
        id: usagePopup

        screen: root.screen
        anchorItem: root
        namespaceSuffix: "usage-popup"
        popupWidth: Style.dropdown.width
        popupHeight: Math.max(Style.popup.minHeight, Math.min(Style.dropdown.maxHeight, panel.item ? panel.item.preferredHeight : Style.popup.minHeight))

        Loader {
            id: panel

            anchors.fill: parent
            active: usagePopup.visible

            sourceComponent: SystemPanel {
            }

        }

    }

}
