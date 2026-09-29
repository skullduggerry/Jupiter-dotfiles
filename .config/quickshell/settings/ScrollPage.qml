import "../style"
import QtQuick

// A page that scrolls once it is taller than the window, with a thin bar at
// its right edge while it can. Its column is the page's usual one; a page
// that is mostly a list passes a wider maximumWidth.
Flickable {
    id: root

    default property alias content: column.data
    property int maximumWidth: Style.settings.pageWidth
    readonly property int columnWidth: Math.min(root.maximumWidth, root.width - Style.settings.padding * 2)

    contentWidth: width
    contentHeight: column.implicitHeight + Style.settings.padding
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: column

        x: Style.settings.padding
        width: root.columnWidth
        spacing: Style.settings.spacing
    }

    // On the page rather than in its content, so it stays put while it scrolls.
    Rectangle {
        parent: root
        visible: root.contentHeight > root.height
        x: root.width - width - Style.widgets.spacing
        y: root.visibleArea.yPosition * root.height
        width: Style.widgets.spacing
        height: root.visibleArea.heightRatio * root.height
        radius: width / 2
        color: Colors.base.border
    }
}
