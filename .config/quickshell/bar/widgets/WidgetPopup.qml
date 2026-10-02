import "../../services"
import "../../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: root

    default property alias content: chrome.data
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

    visible: false
    WlrLayershell.namespace: "quickshell:" + root.namespaceSuffix
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.visible ? root.keyboardFocus : WlrKeyboardFocus.None
    color: Colors.base.panel
    onCoveredAreaChanged: PopupAreas.set(root, root.coveredArea)
    Component.onDestruction: PopupAreas.set(root, null)
    onVisibleChanged: {
        dismiss.stop();
        if (root.visible)
            root.measureAnchor();
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
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
        active: root.visible
        onCleared: dismiss.restart()
    }

    Timer {
        id: dismiss

        interval: Style.popup.dismissDelay
        onTriggered: root.visible = false
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
        Keys.onEscapePressed: root.visible = false
        Keys.onLeftPressed: root.arrow(-1)
        Keys.onRightPressed: root.arrow(1)

        Rectangle {
            id: chrome

            anchors.fill: parent
            radius: Style.bar.radius
            color: Colors.base.surface
            border.color: Colors.base.border
            border.width: Style.border.width
            clip: true

            // Clicks on the panel stay on it rather than dismissing it.
            MouseArea {
                anchors.fill: parent
            }
        }
    }
}
