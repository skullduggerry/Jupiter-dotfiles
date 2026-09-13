// services/DropdownState.qml
//
// Which zone dropdown is open, and on which monitor.
//
// Shared state rather than state inside dropdown/Dropdown.qml because two
// unrelated surfaces drive it: the compositor's three-finger swipe (through
// Dropdown's IpcHandler) and the bar's clock, which opens the calendar zone
// directly. It lives here rather than next to the window it drives so that
// bar/widgets and dropdown/ both depend on services/, instead of on each
// other in a circle.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // The zones, in bar order. Named rather than indexed so a caller can ask
    // for the one it means — the clock wants the calendar wherever the clock
    // happens to sit.
    readonly property string zoneWorkspaces: "workspaces"
    readonly property string zoneCalendar: "calendar"
    readonly property string zoneWifi: "wifi"

    property string zone: root.zoneCalendar
    property bool visible: false

    // Which monitor the dropdown belongs to. Initialised to the first screen
    // so the window has something to attach to before anything opens it;
    // every open() resolves the screen itself and replaces this.
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
        // Swiping over a different zone while one is open swaps the content
        // instead of closing; swiping over the same zone closes it.
        if (root.visible && root.zone === zone) root.close()
        else root.open(zone, screen)
    }

    // The screen containing a point in global layout coordinates, or null if
    // none does. ShellScreen geometry is in the same logical pixels Hyprland
    // reports a cursor position in, so no scale correction is needed.
    //
    // Quickshell.screens is a plain QML list (not an ObjectModel), so it's
    // indexed directly — see PROJECT_STRUCTURE.md on telling the two apart.
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

    // Left third of the monitor under the pointer opens workspaces, middle
    // third the calendar, right third Wi-Fi. Thirds are measured inside the
    // monitor, so the zones line up with the bar on every screen rather than
    // against the global layout.
    function zoneAt(x: real, screen: ShellScreen): string {
        const offset = x - screen.x
        if (offset < screen.width / 3) return root.zoneWorkspaces
        if (offset < screen.width * 2 / 3) return root.zoneCalendar
        return root.zoneWifi
    }

    // Entry point for the compositor's swipe gesture: it reports where the
    // pointer was, and the zone follows from that.
    function openAt(x: real, y: real) {
        const screen = root.screenAt(x, y)
        if (screen === null) {
            // Nothing to anchor to and no zone to pick — a pointer position
            // outside every monitor means the gesture and the shell disagree
            // about the layout, which is worth seeing in the log.
            console.warn("dropdown: no screen contains", x, y)
            return
        }
        root.toggle(root.zoneAt(x, screen), screen)
    }
}
