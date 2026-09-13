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
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
// Every zone's content is a shared panel: the bar opens the same ones from
// its own widgets, so they live in panels/ rather than in either surface.
import "../panels"
import "../services"
import "../style"

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
        // Focus while open, so Escape closes the dropdown the same way it
        // closes a bar popup (WidgetPopup.qml). The Wi-Fi zone's password
        // prompt asks for more than on-demand focus — see WifiWidget.qml for
        // why Exclusive.
        WlrLayershell.keyboardFocus: content.item && content.item.wantsKeyboard
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.OnDemand

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: Colors.base.panel

        // What actually makes the compositor hand keyboard focus to this
        // surface, and hand it back on close. WlrKeyboardFocus.OnDemand on
        // its own is not enough: an on-demand layer surface only gets focus
        // when the user interacts with it, and this one is opened by a
        // gesture or a click on the bar — neither of which is a click on the
        // dropdown. Verified by watching activeFocus with and without it.
        HyprlandFocusGrab {
            windows: [window]
            active: DropdownState.visible
            onCleared: DropdownState.close()
        }

        // Click-outside-to-close catcher, behind the panel.
        MouseArea {
            anchors.fill: parent
            onClicked: DropdownState.close()
        }

        // A focus scope, for the same reason WidgetPopup uses one: the Wi-Fi
        // zone's password field takes focus and hands it back here, and
        // Escape has to still arrive afterwards.
        FocusScope {
            id: surface

            // Sit under the zone that opened it: the left zone opens against
            // the left edge, the right against the right, the middle in the
            // middle — rather than every dropdown appearing top-right the way
            // the bar's WidgetPopups used to.
            x: {
                switch (DropdownState.zone) {
                case DropdownState.zoneWorkspaces: return Style.bar.sideGap
                case DropdownState.zoneWifi: return window.width - surface.width - Style.bar.sideGap
                default: return (window.width - surface.width) / 2
                }
            }
            y: Style.popup.topMargin
            width: Style.dropdown.width

            // Each zone panel reports the height its content actually wants;
            // the bounds are applied here so a panel never has to know how
            // much room the screen has. Without this all three zones were
            // sized for the month grid, and the Wi-Fi list sat in a box with
            // a third of it empty (TODO.md Phase 4).
            height: content.item
                ? Math.max(Style.dropdown.minHeight,
                           Math.min(Style.dropdown.maxHeight, content.item.preferredHeight))
                : Style.dropdown.minHeight
            focus: true

            Keys.onEscapePressed: DropdownState.close()

            Rectangle {
                anchors.fill: parent
                radius: Style.bar.radius
                color: Colors.base.surface
                border.color: Colors.base.border
                border.width: Style.border.width
                clip: true

                // Absorbs clicks on the panel's own background so they don't
                // fall through to the catcher and close it.
                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                // Built only while the dropdown is open, and rebuilt per
                // open, so a closed dropdown costs nothing — no calendar
                // polling, no Wi-Fi scanning, no window list bindings
                // (llm.md §15).
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
