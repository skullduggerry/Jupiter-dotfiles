import "../../panels"
import "../../services"
import "../../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: root

    // Opened and closed by this; the window stays up while the frame goes back
    // into the bar (PopupFrame), taking no input meanwhile.
    property bool open: false
    default property alias content: frame.content
    property string namespaceSuffix: "widget-popup"
    property int popupWidth: Style.popup.width
    property int popupHeight: Style.popup.maxHeight
    property int contentTopMargin: Style.popup.topMargin
    property Item anchorItem: null
    property int keyboardFocus: WlrKeyboardFocus.OnDemand
    property real anchorCenterX: 0
    // What it covers while open, so toasts move below it (PopupAreas).
    readonly property var coveredArea: root.visible && root.screen !== null ? {
        screen: root.screen.name,
        x: contentArea.x,
        y: contentArea.y,
        width: contentArea.width,
        height: contentArea.height
    } : null

    signal wheeled(real deltaX, real deltaY)
    // Left or right, for a popup with neighbours to move to.
    signal arrowPressed(int direction)

    // A text field keeps its arrows, even at either end of its text, where it
    // lets them through to here.
    function arrow(direction: int) {
        if (contentArea.Window.activeFocusItem instanceof TextInput)
            return;

        root.arrowPressed(direction);
    }

    function measureAnchor() {
        if (root.anchorItem === null || root.anchorItem.QsWindow.window === null)
            return;

        const rect = root.anchorItem.QsWindow.itemRect(root.anchorItem);
        root.anchorCenterX = Style.bar.sideGap + rect.x + rect.width / 2;
    }

    visible: frame.shown
    WlrLayershell.namespace: "quickshell:" + root.namespaceSuffix
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.visible ? root.keyboardFocus : WlrKeyboardFocus.None
    color: Colors.base.panel
    mask: root.open ? null : passThrough
    onCoveredAreaChanged: PopupAreas.set(root, root.coveredArea)
    Component.onDestruction: PopupAreas.set(root, null)
    onOpenChanged: {
        dismiss.stop();
        if (root.open)
            root.measureAnchor();
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Region {
        id: passThrough
    }

    Connections {
        function onXChanged() {
            root.measureAnchor();
        }

        function onWidthChanged() {
            root.measureAnchor();
        }

        target: root.anchorItem
        enabled: root.visible
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.open
        onCleared: dismiss.restart()
    }

    Timer {
        id: dismiss

        interval: Style.popup.dismissDelay
        onTriggered: root.open = false
    }

    MouseArea {
        anchors.fill: parent
        onClicked: dismiss.restart()
        onWheel: wheel => {
            dismiss.stop();
            return root.wheeled(wheel.angleDelta.x, wheel.angleDelta.y);
        }
    }

    FocusScope {
        id: contentArea

        // A small bar floating over this screen's windows reserves no strip,
        // and is a pill at its centre, which everything opens under.
        y: root.contentTopMargin + (BarLayout.floats(root.screen) ? Style.bar.floatingClearance : 0)
        x: {
            if (root.screen !== BarLayout.main)
                return (root.width - root.popupWidth) / 2;

            if (root.anchorItem === null)
                return root.width - root.popupWidth - Style.bar.edgeGap;

            const centred = root.anchorCenterX - root.popupWidth / 2;
            return Math.max(Style.bar.edgeGap, Math.min(root.width - root.popupWidth - Style.bar.edgeGap, centred));
        }
        width: root.popupWidth
        height: root.popupHeight
        focus: true
        Keys.onEscapePressed: root.open = false
        Keys.onLeftPressed: root.arrow(-1)
        Keys.onRightPressed: root.arrow(1)

        PopupFrame {
            id: frame

            anchors.fill: parent
            open: root.open
            // Out of the widget it opened from, where it is under one.
            originX: root.screen === BarLayout.main && root.anchorItem !== null ? root.anchorCenterX - contentArea.x : contentArea.width / 2
        }
    }
}
