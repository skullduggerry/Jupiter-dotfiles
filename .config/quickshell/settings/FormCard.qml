import "../style"
import QtQuick

// A Card of rows (FormRow, and whatever goes between them: a note, a
// footer), padded as a panel is and as tall as they are.
Card {
    id: root

    default property alias content: column.data

    implicitHeight: Math.ceil(column.implicitHeight) + Style.bar.padding * 2

    Column {
        id: column

        x: Style.bar.padding
        y: Style.bar.padding
        width: root.width - Style.bar.padding * 2
        spacing: Style.bar.spacing
    }
}
