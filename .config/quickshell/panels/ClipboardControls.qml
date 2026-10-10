import "../services"
import "../style"
import QtQuick

// Clear and the history's switch, for the header of ClipboardPanel and of the
// quick menu's list.
Row {
    id: root

    required property ClipboardHistory clipboard

    spacing: Style.bar.spacing

    TextButton {
        visible: root.clipboard.entries.length > 0
        text: "Clear"
        onClicked: root.clipboard.wipe()
    }

    TextButton {
        text: QuickToggles.clipboardHistory ? "On" : "Off"
        color: QuickToggles.clipboardHistory ? Colors.accent.primary : Colors.text.muted
        onClicked: root.clipboard.setEnabled(!QuickToggles.clipboardHistory)
    }
}
