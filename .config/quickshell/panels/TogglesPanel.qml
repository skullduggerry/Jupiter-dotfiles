import "../services"
import "../style"
import QtQuick

PanelFrame {
    id: root

    implicitHeight: root.chromeHeight + tiles.height
    // How long a click keeps the session awake, or while it does, until when.
    readonly property string caffeineLabel: {
        const minutes = QuickToggles.caffeineMinutes;
        if (QuickToggles.caffeineEnd !== 0)
            return "Caffeine\nuntil " + Qt.formatDateTime(new Date(QuickToggles.caffeineEnd * 60000), "HH:mm");
        if (minutes === 0)
            return "Caffeine\nno limit";
        return "Caffeine\n" + (minutes % 60 === 0 ? minutes / 60 + " h" : minutes + " min");
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
            icon: "\u{F0176}"
            label: root.caffeineLabel
            checked: QuickToggles.caffeine
            onActivated: QuickToggles.setCaffeine(!QuickToggles.caffeine)
            onSecondaryActivated: QuickToggles.cycleCaffeineMinutes()
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
