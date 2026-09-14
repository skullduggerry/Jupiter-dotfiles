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

    signal wheeled(real deltaX, real deltaY)

    function measureAnchor() {
        if (root.anchorItem === null || root.anchorItem.QsWindow.window === null)
            return ;

        const rect = root.anchorItem.QsWindow.itemRect(root.anchorItem);
        root.anchorCenterX = Style.bar.sideGap + rect.x + rect.width / 2;
    }

    visible: false
    WlrLayershell.namespace: "quickshell:" + root.namespaceSuffix
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.visible ? root.keyboardFocus : WlrKeyboardFocus.None
    color: Colors.base.panel
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
        onWheel: (wheel) => {
            dismiss.stop();
            return root.wheeled(wheel.angleDelta.x, wheel.angleDelta.y);
        }
    }

    FocusScope {
        id: contentArea

        y: root.contentTopMargin
        x: {
            if (root.anchorItem === null)
                return root.width - root.popupWidth - Style.bar.sideGap;

            const centred = root.anchorCenterX - root.popupWidth / 2;
            return Math.max(Style.bar.sideGap, Math.min(root.width - root.popupWidth - Style.bar.sideGap, centred));
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

            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }

        }

    }

}
