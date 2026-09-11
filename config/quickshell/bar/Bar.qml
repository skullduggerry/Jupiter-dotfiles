// bar/Bar.qml
import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import "./widgets"
import "../style"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            WlrLayershell.namespace: "quickshell:bar"

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

            implicitHeight: Style.bar.height
            exclusiveZone: Style.bar.height + Style.bar.topGap
            color: Colors.base.panel

            BarContent {}
        }
    }
}
