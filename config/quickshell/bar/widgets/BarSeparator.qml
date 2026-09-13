// bar/widgets/BarSeparator.qml
//
// A hairline between two groups of bar widgets. The design file has one of
// these right after the workspaces (its hidden "Rectangle 6"), and it earns
// its place: the workspace dots and the load ramps are both circles, so
// without it the left of the bar reads as one undifferentiated row of them.
import QtQuick
import "../../style"

Rectangle {
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    width: Style.border.width
    height: Style.bar.separatorHeight
    color: Colors.base.border
}
