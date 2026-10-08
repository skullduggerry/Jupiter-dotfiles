import "../icons"
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
            icon: Icons.bellOff
            label: "Do Not Disturb"
            checked: NotificationService.doNotDisturb
            onActivated: NotificationService.doNotDisturb = !NotificationService.doNotDisturb
        }

        ToggleTile {
            width: tiles.tileWidth
            icon: Icons.plane
            label: "Airplane Mode"
            checked: QuickToggles.airplaneMode
            onActivated: QuickToggles.setAirplaneMode(!QuickToggles.airplaneMode)
        }

        ToggleTile {
            width: tiles.tileWidth
            icon: Icons.moon
            label: "Night Light"
            checked: QuickToggles.nightLight
            onActivated: QuickToggles.setNightLight(!QuickToggles.nightLight)
        }

        ToggleTile {
            width: tiles.tileWidth
            icon: Icons.video
            label: QuickToggles.recording ? "Recording" : "Screen Record"
            checked: QuickToggles.recording
            onActivated: QuickToggles.setRecording(!QuickToggles.recording)
        }

        ToggleTile {
            width: tiles.tileWidth
            icon: Icons.clipboard
            label: "Clipboard"
            checked: QuickToggles.clipboardHistory
            onActivated: QuickToggles.setClipboardHistory(!QuickToggles.clipboardHistory)
            onSecondaryActivated: root.clipboardRequested()
        }

        ToggleTile {
            width: tiles.tileWidth
            icon: Icons.coffee
            label: root.caffeineLabel
            checked: QuickToggles.caffeine
            onActivated: QuickToggles.setCaffeine(!QuickToggles.caffeine)
            onSecondaryActivated: QuickToggles.cycleCaffeineMinutes(1)
        }
    }

    // The way into the Settings app from the quick settings.
    trailing: TextButton {
        text: Icons.settings
        font.family: Icons.font
        color: Colors.icon.active
        font.pixelSize: Style.text.iconSize
        onClicked: SettingsState.show("")
    }
}
