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
            required property ShellScreen modelData

            screen: modelData
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
                screen: modelData
                expanded: root.expanded
                onExpandRequested: root.expanded = !root.expanded
            }

        }

    }

}
