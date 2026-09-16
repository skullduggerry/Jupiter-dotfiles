import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../panels"
import "../services"
import "../style"

Scope {
    id: dropdownScope

    IpcHandler {
        target: "dropdown"

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
        WlrLayershell.keyboardFocus: window.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: Colors.base.panel

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
            onWheel: (wheel) => {
                dismiss.stop();
                if (Math.abs(wheel.angleDelta.x) < Math.abs(wheel.angleDelta.y))
                    return ;

                if (content.item && content.item.swipe)
                    content.item.swipe(wheel.angleDelta.x);
            }
        }

        FocusScope {
            id: surface

            x: {
                switch (DropdownState.zone) {
                case DropdownState.zoneWorkspaces: return Style.bar.edgeGap
                case DropdownState.zoneQuickSettings: return window.width - surface.width - Style.bar.edgeGap
                default: return (window.width - surface.width) / 2
                }
            }
            y: Style.popup.topMargin
            width: Style.dropdown.width

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

                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                Loader {
                    id: content
                    anchors.fill: parent
                    active: DropdownState.visible

                    sourceComponent: {
                        switch (DropdownState.zone) {
                        case DropdownState.zoneWorkspaces: return workspacePanel
                        case DropdownState.zoneQuickSettings: return quickSettingsPanel
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
            id: quickSettingsPanel

            QuickSettingsPanel {
                id: quickSettings

                active: DropdownState.visible
                Component.onCompleted: {
                    const page = quickSettings.pageFor(OsdState.zone);
                    if (page >= 0 && OsdState.recentlyUsed())
                        quickSettings.currentIndex = page;

                }
            }
        }
    }
}
