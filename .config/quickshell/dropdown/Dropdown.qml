// dropdown/Dropdown.qml
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

        HyprlandFocusGrab {
            windows: [window]
            active: DropdownState.visible
            onCleared: DropdownState.close()
        }

        MouseArea {
            anchors.fill: parent
            onClicked: DropdownState.close()
        }

        FocusScope {
            id: surface

            x: {
                switch (DropdownState.zone) {
                case DropdownState.zoneWorkspaces: return Style.bar.sideGap
                case DropdownState.zoneWifi: return window.width - surface.width - Style.bar.sideGap
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
