// bar/widgets/WidgetPopup.qml
//
// Shared "click outside to close" popup shell for bar widgets that need a
// small dropdown under their own icon (Bluetooth, Wi-Fi, power menu, ...).
// One fullscreen transparent overlay window with the real content positioned
// on top of it, so any click outside the content closes the popup — the same
// trick as Launcher.qml's dimmed backdrop.
//
// Usage:
//   WidgetPopup {
//       id: myPopup
//       screen: root.screen
//       anchorItem: root
//       namespaceSuffix: "my-popup"
//       ListView { ... }
//   }
//   myPopup.visible = !myPopup.visible
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../style"

PanelWindow {
    id: root

    // Children declared inside `WidgetPopup { ... }` are reparented into the
    // chrome, so callers can write plain content without knowing about the
    // focus scope wrapped around it.
    default property alias content: chrome.data

    // Distinguishes this popup's layer-shell namespace from others (e.g.
    // "quickshell:bt-popup" vs "quickshell:wifi-popup") so compositor
    // window rules can still target a specific popup by name.
    property string namespaceSuffix: "widget-popup"

    property int popupWidth: Style.popup.width
    property int popupHeight: Style.popup.maxHeight
    property int contentTopMargin: Style.popup.topMargin

    // The bar widget this popup belongs to. The popup centres itself under
    // that widget instead of every popup opening in the same top-right
    // corner; without one it falls back to the right edge.
    property Item anchorItem: null

    // Popups take focus while they are open, which is what lets Escape close
    // them; the compositor hands it back to whatever had it when the popup
    // goes away. That is a real trade-off — a click on the bar now
    // interrupts typing — but a dropdown that cannot be dismissed from the
    // keyboard was the worse half of it.
    //
    // A popup with an input of its own can raise this further; see
    // WifiWidget, and why its prompt asks for Exclusive.
    property int keyboardFocus: WlrKeyboardFocus.OnDemand

    // Horizontal centre of `anchorItem` in this window's coordinates.
    //
    // Measured rather than bound: QsWindow.itemRect() is a plain method, not
    // a bindable property, so the Connections below re-measure when the
    // widget moves (a tray item appearing shifts everything left of it).
    // The two windows use different frames — this one covers the screen,
    // while the bar starts Style.bar.sideGap in from the screen's left edge
    // (Bar.qml anchors it there) — and QsWindow exposes no absolute position
    // to reconcile them with, so that token does it.
    property real anchorCenterX: 0

    function measureAnchor() {
        // itemRect() throws for an item that isn't in a window yet, which is
        // the state the bar widget is in while the shell is still building it.
        if (root.anchorItem === null || root.anchorItem.QsWindow.window === null) return
        const rect = root.anchorItem.QsWindow.itemRect(root.anchorItem)
        root.anchorCenterX = Style.bar.sideGap + rect.x + rect.width / 2
    }

    visible: false

    WlrLayershell.namespace: "quickshell:" + root.namespaceSuffix
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.visible ? root.keyboardFocus : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: Colors.base.panel

    onVisibleChanged: if (root.visible) root.measureAnchor()

    Connections {
        target: root.anchorItem
        enabled: root.visible

        function onXChanged() { root.measureAnchor() }
        function onWidthChanged() { root.measureAnchor() }
    }

    // What actually makes the compositor hand keyboard focus to this
    // surface, and hand it back on close. WlrKeyboardFocus.OnDemand on its
    // own is not enough: an on-demand layer surface only gets focus when the
    // user interacts with it, and the click that opens this one lands on the
    // bar, which is a different surface. Verified by watching activeFocus
    // with the grab and without it.
    //
    // A grab also supersedes any grab already out, so opening a second popup
    // (or the gesture dropdown) closes the first — which is how a menu bar is
    // expected to behave, and was not true before.
    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: root.visible = false
    }

    // Fullscreen click-outside catcher. Sits behind the content; any click
    // that isn't absorbed by the popup lands here and closes it.
    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    // A focus scope rather than a plain Item so that Escape still arrives
    // here after a child input gives focus back (the Wi-Fi password prompt
    // does exactly that), instead of activeFocus being left nowhere.
    FocusScope {
        id: contentArea

        y: root.contentTopMargin
        // Centred under the widget that owns it, kept inside the screen so a
        // popup belonging to the leftmost or rightmost widget doesn't hang
        // off the edge. The bar's own side gap is the margin either way.
        x: {
            if (root.anchorItem === null) return root.width - root.popupWidth - Style.bar.sideGap
            const centred = root.anchorCenterX - root.popupWidth / 2
            return Math.max(Style.bar.sideGap,
                            Math.min(root.width - root.popupWidth - Style.bar.sideGap, centred))
        }
        width: root.popupWidth
        height: root.popupHeight
        focus: true

        Keys.onEscapePressed: root.visible = false

        Rectangle {
            id: chrome

            anchors.fill: parent
            radius: Style.bar.radius
            color: Colors.base.surface
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
}
