import "../services"
import "../style"
import QtQuick
import Quickshell.Services.UPower

PanelFrame {
    id: root

    implicitHeight: root.chromeHeight + tiles.height
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

    // The Clipboard tile's right click: its history, on the page after this one.
    signal clipboardRequested

    title: "Toggles"

    Grid {
        id: tiles

        readonly property real tileWidth: (width - Style.toggles.tileSpacing * (tiles.columns - 1)) / tiles.columns

        width: parent.width
        columns: Style.toggles.tileColumns
        spacing: Style.toggles.tileSpacing

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
            icon: "\u{F044A}"
            label: QuickToggles.recording ? "Recording" : "Screen Record"
            checked: QuickToggles.recording
            onActivated: QuickToggles.setRecording(!QuickToggles.recording)
        }

        ToggleTile {
            width: tiles.tileWidth
            icon: "\u{F0147}"
            label: "Clipboard"
            checked: QuickToggles.clipboardHistory
            onActivated: QuickToggles.setClipboardHistory(!QuickToggles.clipboardHistory)
            onSecondaryActivated: root.clipboardRequested()
        }

        ToggleTile {
            width: tiles.tileWidth
            icon: root.powerProfileIcon
            label: QuickToggles.profileName(PowerProfiles.profile)
            checked: PowerProfiles.profile !== PowerProfile.Balanced
            onActivated: QuickToggles.cyclePowerProfile()
        }
    }

    // The way into the Settings app from the quick settings.
    trailing: TextButton {
        text: "\u{F08BB}"
        color: Colors.icon.active
        font.pixelSize: Style.text.iconSize
        onClicked: SettingsState.show("")
    }
}
