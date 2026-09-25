import "../style"
import "./widgets"
import QtQuick
import Quickshell

Rectangle {
    id: root

    required property ShellScreen screen
    required property bool expanded

    signal expandRequested()

    anchors.fill: parent
    anchors.margins: Style.border.width
    radius: Style.bar.radius
    color: Colors.base.surface
    border.color: Colors.base.border
    border.width: Style.border.width

    Row {
        id: left

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

    }

    Row {
        spacing: Style.bar.spacing

        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }

        ClockWidget {
            screen: root.screen
        }

    }

    Row {
        id: rightLead

        spacing: Style.bar.spacing

        anchors {
            right: drawer.left
            rightMargin: Style.bar.spacing
            verticalCenter: parent.verticalCenter
        }

        NotificationWidget {
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
            right: right.left
            verticalCenter: parent.verticalCenter
        }

        SystemTrayWidget {
            screen: root.screen
        }

        BrightnessWidget {
            pager: quickPager
        }

        BluetoothWidget {
            screen: root.screen
            pager: quickPager
        }

        VolumeWidget {
            pager: quickPager
        }

        WifiWidget {
            screen: root.screen
            pager: quickPager
        }

    }

    Row {
        id: right

        anchors.rightMargin: Style.bar.padding
        spacing: Style.bar.spacing

        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }

        BatteryWidget {
            screen: root.screen
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
