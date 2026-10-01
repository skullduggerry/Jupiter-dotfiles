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

    PanelWindow {
        id: window

        // What it covers while open, so toasts move below it (PopupAreas).
        readonly property var coveredArea: DropdownState.visible && window.screen !== null ? {
            screen: window.screen.name,
            x: surface.x,
            y: surface.y,
            width: surface.width,
            height: surface.height
        } : null

        visible: DropdownState.visible
        screen: DropdownState.screen
        WlrLayershell.namespace: "quickshell:dropdown"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: window.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: Colors.base.panel
        onCoveredAreaChanged: PopupAreas.set(window, window.coveredArea)
        Component.onDestruction: PopupAreas.set(window, null)

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        HyprlandFocusGrab {
            windows: [window]
            active: DropdownState.visible
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
                switch (DropdownState.zone) {
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
            y: Style.popup.topMargin + (BarLayout.floats(window.screen) ? Style.bar.floatingGap + Style.bar.height + Style.bar.bottomGap : 0)
            width: Style.dropdown.width
            height: Math.max(Style.dropdown.minHeight, Math.min(Style.dropdown.maxHeight, Math.floor(content.implicitHeight)))
            focus: true
            Keys.onEscapePressed: DropdownState.close()
            Keys.onLeftPressed: surface.step(-1)
            Keys.onRightPressed: surface.step(1)

            Rectangle {
                anchors.fill: parent
                radius: Style.bar.radius
                color: Colors.base.surface
                border.color: Colors.base.border
                border.width: Style.border.width
                clip: true

                // Clicks on the panel stay on it rather than dismissing it.
                MouseArea {
                    anchors.fill: parent
                }

                Loader {
                    id: content

                    anchors.fill: parent
                    active: DropdownState.visible
                    sourceComponent: {
                        switch (DropdownState.zone) {
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
                screen: DropdownState.screen
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
