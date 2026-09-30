import "../style"
import QtQuick

// One of Icons' glyphs, at the bar's icon size and in its icon colour unless
// told otherwise: `Icon { text: Icons.bell }`.
Text {
    font.family: Icons.font
    font.pixelSize: Style.text.iconSize
    color: Colors.icon.active
}
