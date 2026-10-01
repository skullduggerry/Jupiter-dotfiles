pragma ComponentBehavior: Bound

import "../services"
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

    // The power button opens the power menu, which is on the bar.
    Binding {
        target: PowerButton
        property: "active"
        value: true
    }

    // The full bar on BarLayout.main, and the small one, as wide as it is and
    // centred, on every other screen. Each screen keeps its one window when
    // the full bar moves, so Caffeine's inhibitors, which Hyprland only weighs
    // on a window mapped before them, keep counting.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property ShellScreen modelData
            readonly property bool full: bar.modelData === BarLayout.main
            // Caffeine for the inhibitor below: bound to QuickToggles.caffeine
            // itself, it logs a binding loop at start now that the content is
            // in a Loader; through a property of the window it does not.
            readonly property bool caffeine: QuickToggles.caffeine

            screen: bar.modelData
            WlrLayershell.namespace: "quickshell:bar"
            implicitWidth: content.implicitWidth + Style.border.width * 2
            implicitHeight: Style.bar.height
            exclusiveZone: BarLayout.floats(bar.modelData) ? 0 : Style.bar.height + Style.bar.bottomGap
            color: Colors.base.panel

            anchors {
                top: true
                left: bar.full
                right: bar.full
            }

            margins {
                top: BarLayout.floats(bar.modelData) ? Style.bar.floatingGap : Style.bar.topGap
                left: Style.bar.sideGap
                right: Style.bar.sideGap
            }

            Loader {
                id: content

                anchors.fill: parent
                sourceComponent: bar.full ? fullBar : smallBar
            }

            Component {
                id: fullBar

                BarContent {
                    screen: bar.modelData
                    expanded: root.expanded
                    onExpandRequested: root.expanded = !root.expanded
                }
            }

            Component {
                id: smallBar

                SmallBarContent {
                    screen: bar.modelData
                }
            }

            BackdropProbe {
                screen: bar.modelData
            }

            // Caffeine, on the Toggles page: an inhibitor needs a window, and
            // every screen has a bar.
            IdleInhibitor {
                window: bar
                enabled: bar.caffeine
            }
        }
    }
}
