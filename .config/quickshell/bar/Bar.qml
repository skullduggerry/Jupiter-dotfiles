pragma ComponentBehavior: Bound

import "../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

Scope {
    id: root

    property bool expanded: false

    GlobalShortcut {
        name: "barExpand"
        onPressed: root.expanded = !root.expanded
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property ShellScreen modelData

            screen: bar.modelData
            WlrLayershell.namespace: "quickshell:bar"
            implicitHeight: Style.bar.height
            exclusiveZone: Style.bar.height + Style.bar.bottomGap
            color: Colors.base.panel

            anchors {
                top: true
                left: true
                right: true
            }

            margins {
                top: Style.bar.topGap
                left: Style.bar.sideGap
                right: Style.bar.sideGap
            }

            BarContent {
                screen: bar.modelData
                expanded: root.expanded
                onExpandRequested: root.expanded = !root.expanded
            }
        }
    }
}
