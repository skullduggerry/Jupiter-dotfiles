import "../style"
import "./widgets"
import QtQuick
import Quickshell

Rectangle {
    id: root

    required property ShellScreen screen

    anchors.fill: parent
    anchors.margins: 1
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
        id: right

        anchors.rightMargin: Style.bar.padding
        spacing: Style.bar.spacing

        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }

        NotificationWidget {
            screen: root.screen
        }

        SystemTrayWidget {
            screen: root.screen
        }

        BrightnessWidget {
            pager: quickPager
        }

        VolumeWidget {
            pager: quickPager
        }

        WifiWidget {
            screen: root.screen
            pager: quickPager
        }

        BluetoothWidget {
            screen: root.screen
            pager: quickPager
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
