import "../panels"
import "../style"
import "./widgets"
import QtQuick
import Quickshell

// The bar on every screen but the one with the full bar (BarLayout.main): the
// screen's workspaces, the clock and the notifications. Both sides are as wide
// as the wider of them, so the clock stays at the screen's centre however many
// workspaces there are.
Rectangle {
    id: root

    required property ShellScreen screen
    readonly property real side: Math.max(workspaces.implicitWidth, notifications.implicitWidth) + Style.bar.spacing

    implicitWidth: clock.implicitWidth + root.side * 2 + Style.bar.padding * 2
    anchors.fill: parent
    anchors.margins: Style.border.width
    radius: Style.bar.radius
    color: Colors.base.surface
    border.color: Colors.base.edge
    border.width: Style.border.width

    // The bar's layer is the glass, so Hyprland's lens frames it.
    GlassHighlight {
        lensed: true
    }

    WorkspaceWidget {
        id: workspaces

        screen: root.screen

        anchors {
            right: clock.left
            rightMargin: Style.bar.spacing
            verticalCenter: parent.verticalCenter
        }
    }

    ClockWidget {
        id: clock

        anchors.centerIn: parent
        screen: root.screen
    }

    NotificationWidget {
        id: notifications

        screen: root.screen

        anchors {
            left: clock.right
            leftMargin: Style.bar.spacing
            verticalCenter: parent.verticalCenter
        }
    }
}
