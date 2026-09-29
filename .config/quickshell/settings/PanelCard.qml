import "../style"
import QtQuick

// A quick-settings panel as a Settings page: the page's column wide, as tall
// as the panel wants and the window allows, in the dropdowns' frame. The panel
// brings its own padding, as it does in a dropdown.
Item {
    id: root

    default property alias content: card.data
    property int preferredHeight: 0

    Card {
        id: card

        x: Style.settings.padding
        width: Math.min(Style.settings.pageWidth, root.width - Style.settings.padding * 2)
        height: Math.min(root.preferredHeight, root.height - Style.settings.padding)
    }
}
