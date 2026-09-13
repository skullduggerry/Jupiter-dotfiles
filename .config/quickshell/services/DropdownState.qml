// services/DropdownState.qml
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string zoneWorkspaces: "workspaces"
    readonly property string zoneCalendar: "calendar"
    readonly property string zoneWifi: "wifi"

    property string zone: root.zoneCalendar
    property bool visible: false

    property ShellScreen screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    function open(zone: string, screen: ShellScreen) {
        if (screen !== null) root.screen = screen
        root.zone = zone
        root.visible = true
    }

    function close() {
        root.visible = false
    }

    function toggle(zone: string, screen: ShellScreen) {
        if (root.visible && root.zone === zone) root.close()
        else root.open(zone, screen)
    }

    function screenAt(x: real, y: real): ShellScreen {
        for (let index = 0; index < Quickshell.screens.length; index++) {
            const candidate = Quickshell.screens[index]
            if (x >= candidate.x && x < candidate.x + candidate.width
                && y >= candidate.y && y < candidate.y + candidate.height) {
                return candidate
            }
        }
        return null
    }

    function zoneAt(x: real, screen: ShellScreen): string {
        const offset = x - screen.x
        if (offset < screen.width / 3) return root.zoneWorkspaces
        if (offset < screen.width * 2 / 3) return root.zoneCalendar
        return root.zoneWifi
    }

    function openAt(x: real, y: real) {
        const screen = root.screenAt(x, y)
        if (screen === null) {
            console.warn("dropdown: no screen contains", x, y)
            return
        }
        root.toggle(root.zoneAt(x, screen), screen)
    }
}
