// bar/widgets/WidgetPopup.qml
//
// Shared "click outside to close" popup shell for bar widgets that need a
// small dropdown anchored near the top-right of the bar (Bluetooth, Wi-Fi,
// power menu, ...). Implements the fullscreen transparent catcher window
// called out in TODO.md, reusing the same trick as Launcher.qml's dimmed
// backdrop: one fullscreen overlay window with the real content positioned
// on top of it, so any click outside the content closes the popup.
//
// Usage:
//   WidgetPopup {
//       id: myPopup
//       screen: root.screen
//       namespaceSuffix: "my-popup"
//       ListView { ... }
//   }
//   myPopup.visible = !myPopup.visible
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../style"

PanelWindow {
    id: root

    // Children declared inside `WidgetPopup { ... }` are reparented here,
    // so callers can write plain content without knowing about contentArea.
    default property alias content: contentArea.data

    // Distinguishes this popup's layer-shell namespace from others (e.g.
    // "quickshell:bt-popup" vs "quickshell:wifi-popup") so compositor
    // window rules can still target a specific popup by name.
    property string namespaceSuffix: "widget-popup"

    property int popupWidth: Style.popup.width
    property int popupHeight: Style.popup.maxHeight
    property int contentTopMargin: Style.bar.topGap + Style.bar.height + 4
    property int contentRightMargin: Style.bar.sideGap

    visible: false

    WlrLayershell.namespace: "quickshell:" + root.namespaceSuffix
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    // Fullscreen click-outside catcher. Sits behind contentArea; any click
    // that isn't absorbed by the popup content lands here and closes it.
    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Rectangle {
        id: contentArea
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: root.contentTopMargin
        anchors.rightMargin: root.contentRightMargin
        width: root.popupWidth
        height: root.popupHeight
        radius: Style.bar.radius
        color: Qt.rgba(Colors.base.base.r, Colors.base.base.g, Colors.base.base.b, Colors.base.opacity)
        border.color: Colors.base.border
        border.width: Style.border.width
        clip: true

        // Absorbs clicks on the popup's own background/padding so they
        // don't fall through to the catcher above and close the popup.
        // Declared first so real content (added via the default property)
        // paints on top of it and still receives its own click handling.
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }
    }
}
