pragma ComponentBehavior: Bound

import "../panels"
import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

Scope {
    IpcHandler {
        // A zone from a pointer position, as the three-finger swipe sends it.
        function openAt(x: real, y: real): void {
            DropdownState.openAt(x, y);
        }

        function open(zone: string): void {
            DropdownState.open(zone, null);
        }

        function close(): void {
            DropdownState.close();
        }

        target: "dropdown"
    }

    // SUPER+D: the calendar on the focused screen, the arrows going on to the
    // workspaces and the quick settings.
    GlobalShortcut {
        name: "calendarToggle"
        onPressed: DropdownState.toggle(DropdownState.zoneCalendar, Screens.focused)
    }

    PanelWindow {
        id: window

        // The zone it shows, and on which screen: DropdownState's. While it
        // is up, another zone on Swoosh (a swipe over another third, the
        // arrows) waits for the frame to go back into the bar, so the new one
        // comes out of the bar itself; so does another screen, on Fade too,
        // as the window is built anew there and must take the grab afresh.
        property string zone
        readonly property bool current: window.zone === DropdownState.zone && window.screen === DropdownState.screen

        function follow() {
            window.screen = DropdownState.screen;
            window.zone = DropdownState.zone;
        }

        function requested() {
            if (!window.visible || (!Theme.swoosh && window.screen === DropdownState.screen))
                window.follow();
        }

        // What it covers while open, so toasts move below it (PopupAreas).
        readonly property var coveredArea: window.visible && window.screen !== null ? {
            screen: window.screen.name,
            x: surface.x,
            y: surface.y,
            width: surface.width,
            height: surface.height
        } : null

        // Up while the frame goes back into the bar too (PopupFrame), taking
        // no input meanwhile, and between two zones.
        visible: frame.shown || DropdownState.visible
        WlrLayershell.namespace: "quickshell:dropdown"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: window.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: Colors.base.panel
        mask: DropdownState.visible ? null : passThrough
        onCoveredAreaChanged: PopupAreas.set(window, window.coveredArea)
        Component.onCompleted: window.follow()
        Component.onDestruction: PopupAreas.set(window, null)

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Region {
            id: passThrough
        }

        Connections {
            function onZoneChanged() {
                window.requested();
            }

            function onScreenChanged() {
                window.requested();
            }

            target: DropdownState
        }

        HyprlandFocusGrab {
            windows: [window]
            active: DropdownState.visible && window.screen === DropdownState.screen
            onCleared: dismiss.restart()
        }

        Timer {
            id: dismiss

            interval: Style.popup.dismissDelay
            onTriggered: DropdownState.close()
        }

        MouseArea {
            anchors.fill: parent
            onClicked: dismiss.restart()
            onWheel: wheel => {
                dismiss.stop();
                if (Math.abs(wheel.angleDelta.x) >= Math.abs(wheel.angleDelta.y))
                    (content.item as QuickSettingsPanel)?.swipe(wheel.angleDelta.x);
            }
        }

        FocusScope {
            id: surface

            function step(direction: int) {
                // A text field keeps its arrows, even at either end of its
                // text, where it lets them through to here.
                if (surface.Window.activeFocusItem instanceof TextInput)
                    return;

                // The quick-settings pages are steps of their own, so the
                // strip only leaves that zone past its first or last page.
                if ((content.item as QuickSettingsPanel)?.step(direction, false))
                    return;

                DropdownState.step(direction);
            }

            x: {
                // A small bar is a pill at the screen's centre: every zone
                // opens under it.
                if (window.screen !== BarLayout.main)
                    return (window.width - surface.width) / 2;

                switch (window.zone) {
                case DropdownState.zoneWorkspaces:
                    return Style.bar.edgeGap;
                case DropdownState.zoneQuickSettings:
                    return window.width - surface.width - Style.bar.edgeGap;
                default:
                    return (window.width - surface.width) / 2;
                }
            }
            // A small bar floating over this screen's windows reserves no
            // strip, so the dropdown clears it by itself.
            y: Style.popup.topMargin + (BarLayout.floats(window.screen) ? Style.bar.floatingClearance : 0)
            width: Style.dropdown.width
            height: Math.max(Style.dropdown.minHeight, Math.min(Style.dropdown.maxHeight, Math.floor(content.implicitHeight)))
            focus: true
            Keys.onEscapePressed: DropdownState.close()
            Keys.onLeftPressed: surface.step(-1)
            Keys.onRightPressed: surface.step(1)

            PopupFrame {
                id: frame

                anchors.fill: parent
                open: DropdownState.visible && window.current
                // Back in the bar on its way to another zone: that one comes
                // out. A turn later, as taking it up opens the frame again,
                // which `shown` itself depends on, and lets the grab go first.
                onShownChanged: {
                    if (!frame.shown)
                        Qt.callLater(window.follow);
                }

                Loader {
                    id: content

                    anchors.fill: parent
                    active: window.visible
                    sourceComponent: {
                        switch (window.zone) {
                        case DropdownState.zoneWorkspaces:
                            return workspacePanel;
                        case DropdownState.zoneQuickSettings:
                            return quickSettingsPanel;
                        default:
                            return calendarPanel;
                        }
                    }
                }
            }
        }

        Component {
            id: workspacePanel

            WorkspacePanel {
                screen: window.screen
                onActivated: DropdownState.close()
            }
        }

        Component {
            id: calendarPanel

            CalendarPanel {}
        }

        Component {
            id: quickSettingsPanel

            QuickSettingsPanel {
                id: quickSettings

                active: DropdownState.visible
                // Right after a volume or brightness key, on that page.
                Component.onCompleted: {
                    const page = quickSettings.pageFor(OsdState.zone);
                    if (page >= 0 && OsdState.recentlyUsed())
                        quickSettings.currentIndex = page;
                }
            }
        }
    }
}
