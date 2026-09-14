import "../style"
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
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
            }

        }

    }

}
