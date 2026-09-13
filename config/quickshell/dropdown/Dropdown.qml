// dropdown/Dropdown.qml
//
// One overlay window for all three swipe zones, swapping its content by zone
// instead of running a window per panel (TODO.md Phase 3). Same overlay
// pattern as Launcher.qml: a fullscreen transparent window, the panel drawn
// on top of it, and a click anywhere else closing it.
//
// The trigger is Hyprland's own three-finger gesture calling in over IPC —
// see the `hl.gesture` block in config/hypr/modules/keybinds.lua. Zone
// selection lives in DropdownState so the bar's clock can open the calendar
// zone without going through the compositor.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "../style"
// For WifiPanel: the right zone shows the same network list as the bar's
// Wi-Fi widget, so it uses that widget's panel rather than a second copy.
import "../bar/widgets"

Scope {
    id: dropdownScope

    // Manual/scripted trigger, and what the gesture calls:
    //   qs ipc call dropdown openAt 904 740
    //   qs ipc call dropdown open calendar
    IpcHandler {
        target: "dropdown"

        // Pointer position in global layout coordinates; the zone and the
        // monitor both follow from it.
        function openAt(x: real, y: real): void { DropdownState.openAt(x, y) }
        function open(zone: string): void { DropdownState.open(zone, null) }
        function close(): void { DropdownState.close() }
    }

    PanelWindow {
        id: window

        visible: DropdownState.visible
        screen: DropdownState.screen

        WlrLayershell.namespace: "quickshell:dropdown"
        WlrLayershell.layer: WlrLayer.Overlay
        // Only the Wi-Fi zone's password prompt ever wants the keyboard, and
        // it wants it for certain — see WifiWidget.qml for why Exclusive.
        WlrLayershell.keyboardFocus: content.item && content.item.wantsKeyboard
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"

        // Click-outside-to-close catcher, behind the panel.
        MouseArea {
            anchors.fill: parent
            onClicked: DropdownState.close()
        }

        Rectangle {
            id: surface

            // Sit under the zone that opened it: the left zone opens against
            // the left edge, the right against the right, the middle in the
            // middle — rather than every dropdown appearing top-right the way
            // the bar's WidgetPopups do.
            x: {
                switch (DropdownState.zone) {
                case DropdownState.zoneWorkspaces: return Style.bar.sideGap
                case DropdownState.zoneWifi: return window.width - surface.width - Style.bar.sideGap
                default: return (window.width - surface.width) / 2
                }
            }
            y: Style.popup.topMargin
            width: Style.dropdown.width
            height: Style.dropdown.height
            radius: Style.bar.radius
            color: Colors.base.surface
            border.color: Colors.base.border
            border.width: Style.border.width
            clip: true

            // Absorbs clicks on the panel's own background so they don't fall
            // through to the catcher and close it.
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            // Built only while the dropdown is open, and rebuilt per open, so
            // a closed dropdown costs nothing — no calendar polling, no Wi-Fi
            // scanning, no window list bindings (llm.md §15).
            Loader {
                id: content
                anchors.fill: parent
                active: DropdownState.visible

                sourceComponent: {
                    switch (DropdownState.zone) {
                    case DropdownState.zoneWorkspaces: return workspacePanel
                    case DropdownState.zoneWifi: return wifiPanel
                    default: return calendarPanel
                    }
                }
            }
        }

        Component {
            id: workspacePanel

            WorkspacePanel {
                screen: DropdownState.screen
                onActivated: DropdownState.close()
            }
        }

        Component {
            id: calendarPanel

            CalendarPanel {}
        }

        Component {
            id: wifiPanel

            WifiPanel {
                active: DropdownState.visible
            }
        }
    }
}
