import "../services"
import "../style"
import QtQuick
import Quickshell.Services.UPower

Item {
    id: root

    readonly property int preferredHeight: Style.bar.padding * 2 + header.height + Style.border.width + Style.bar.spacing + tiles.height
    readonly property string powerProfileLabel: {
        switch (PowerProfiles.profile) {
        case PowerProfile.PowerSaver:
            return "Power Saver";
        case PowerProfile.Performance:
            return "Performance";
        default:
            return "Balanced";
        }
    }
    readonly property string powerProfileIcon: {
        switch (PowerProfiles.profile) {
        case PowerProfile.PowerSaver:
            return "\u{F0F86}";
        case PowerProfile.Performance:
            return "\u{F04C5}";
        default:
            return "\u{F0F85}";
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: Style.bar.padding

        Item {
            id: header

            height: Style.popup.itemHeight

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            Text {
                text: "Toggles"
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size

                anchors {
                    left: parent.left
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
                left: parent.left
                right: parent.right
            }

        }

        Grid {
            id: tiles

            readonly property real tileWidth: (width - Style.toggles.tileSpacing * (tiles.columns - 1)) / tiles.columns

            columns: Style.toggles.tileColumns
            spacing: Style.toggles.tileSpacing

            anchors {
                top: separator.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.bar.spacing
            }

            ToggleTile {
                width: tiles.tileWidth
                icon: "\u{F009B}"
                label: "Do Not Disturb"
                checked: NotificationService.doNotDisturb
                onActivated: NotificationService.doNotDisturb = !NotificationService.doNotDisturb
            }

            ToggleTile {
                width: tiles.tileWidth
                icon: "\u{F001D}"
                label: "Airplane Mode"
                checked: QuickToggles.airplaneMode
                onActivated: QuickToggles.setAirplaneMode(!QuickToggles.airplaneMode)
            }

            ToggleTile {
                width: tiles.tileWidth
                icon: "\u{F0594}"
                label: "Night Light"
                checked: QuickToggles.nightLight
                onActivated: QuickToggles.setNightLight(!QuickToggles.nightLight)
            }

            ToggleTile {
                width: tiles.tileWidth
                icon: root.powerProfileIcon
                label: root.powerProfileLabel
                checked: PowerProfiles.profile !== PowerProfile.Balanced
                onActivated: QuickToggles.cyclePowerProfile()
            }

        }

    }

}
