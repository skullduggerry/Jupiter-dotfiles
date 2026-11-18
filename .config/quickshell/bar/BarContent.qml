import "../panels"
import "../style"
import "./widgets"
import QtQuick
import Quickshell

Rectangle {
    id: root

    required property ShellScreen screen
    required property bool expanded

    signal expandRequested

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

    Row {
        id: leftRow

        anchors.leftMargin: Style.bar.padding
        spacing: Style.bar.spacing

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }

        WorkspaceWidget {
            screen: root.screen
        }

        SystemUsageWidget {
            screen: root.screen
        }
        ShelfWidget {
            screen: root.screen
        }
        MediaWidget {
            id: media

            screen: root.screen
            // Up to the clock, never under it.
            maximumWidth: clock.x - Style.bar.spacing - leftRow.x - media.x
        }
    }

    ClockWidget {
        id: clock

        anchors.centerIn: parent
        screen: root.screen
    }

    Row {
        spacing: Style.bar.spacing

        anchors {
            right: drawer.left
            rightMargin: Style.bar.spacing
            verticalCenter: parent.verticalCenter
        }

        NotificationWidget {
            screen: root.screen
        }
        KeyboardWidget {
            screen: root.screen
        }
        TogglesWidget {
            pager: quickPager
            onExpandRequested: root.expandRequested()
        }
    }

    BarDrawer {
        id: drawer

        expanded: root.expanded

        anchors {
            right: rightRow.left
            verticalCenter: parent.verticalCenter
        }

        SystemTrayWidget {
            screen: root.screen
        }

        BrightnessWidget {
            pager: quickPager
            shown: root.expanded
        }

        BluetoothWidget {
            pager: quickPager
        }

        VolumeWidget {
            pager: quickPager
        }

        WifiWidget {
            pager: quickPager
        }
    }

    Row {
        id: rightRow

        anchors.rightMargin: Style.bar.padding
        spacing: Style.bar.spacing

        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }

        BatteryWidget {
            pager: quickPager
        }

        PowerWidget {
            screen: root.screen
        }
    }

    QuickPager {
        id: quickPager

        screen: root.screen
    }
}
