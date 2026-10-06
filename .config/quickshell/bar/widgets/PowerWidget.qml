pragma ComponentBehavior: Bound

import "../../icons"
import "../../services"
import "../../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    required property ShellScreen screen

    implicitWidth: icon.implicitWidth + Style.widgets.padding * 2
    implicitHeight: Style.bar.height

    Icon {
        id: icon

        anchors.centerIn: parent
        text: Icons.power
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            actions.current = -1;
            powerPopup.open = !powerPopup.open;
        }
    }

    // Open rather than toggle: a press can come in on both of the ACPI power
    // button devices, and a second toggle would close the menu again. Opened
    // from the keyboard, the first action is highlighted, for the arrow keys;
    // never a destructive one, so a stray Enter only locks.
    Connections {
        function onMenuRequested() {
            actions.current = 0;
            powerPopup.open = true;
        }

        target: PowerButton
    }

    WidgetPopup {
        id: powerPopup

        screen: root.screen
        anchorItem: root
        namespaceSuffix: "power-popup"
        popupWidth: Style.popup.width
        popupHeight: actions.implicitHeight + Style.bar.padding * 2

        // Up and Down (Tab and Shift+Tab too) move the highlight, wrapping;
        // Enter or Space runs it.
        Column {
            id: actions

            // The highlighted action, -1 until a key or the pointer picks one.
            property int current: -1
            readonly property var choices: [
                {
                    label: "Lock",
                    danger: false,
                    run: () => LockService.lock()
                },
                {
                    label: "Logout",
                    danger: false,
                    run: () => Hyprland.dispatch("hl.dsp.exit()")
                },
                {
                    label: "Suspend",
                    danger: false,
                    run: () => Quickshell.execDetached(["systemctl", "suspend"])
                },
                {
                    label: "Reboot",
                    danger: true,
                    run: () => Quickshell.execDetached(["systemctl", "reboot"])
                },
                {
                    label: "Shutdown",
                    danger: true,
                    run: () => Quickshell.execDetached(["systemctl", "poweroff"])
                }
            ]

            function step(by: int) {
                const count = actions.choices.length;
                actions.current = actions.current < 0 ? (by > 0 ? 0 : count - 1) : (actions.current + by + count) % count;
            }

            function run(index: int) {
                if (index < 0)
                    return;

                powerPopup.open = false;
                actions.choices[index].run();
            }

            anchors.fill: parent
            anchors.margins: Style.bar.padding
            spacing: Style.widgets.spacing
            focus: true
            Keys.onUpPressed: actions.step(-1)
            Keys.onDownPressed: actions.step(1)
            Keys.onTabPressed: actions.step(1)
            Keys.onBacktabPressed: actions.step(-1)
            Keys.onReturnPressed: actions.run(actions.current)
            Keys.onEnterPressed: actions.run(actions.current)
            Keys.onSpacePressed: actions.run(actions.current)

            Repeater {
                model: actions.choices

                delegate: PowerAction {
                    id: action

                    required property var modelData
                    required property int index

                    label: action.modelData.label
                    labelColor: action.modelData.danger ? Colors.power.danger : Colors.text.base
                    highlighted: actions.current === action.index
                    onHovered: actions.current = action.index
                    onActivated: actions.run(action.index)
                }
            }
        }
    }
}
