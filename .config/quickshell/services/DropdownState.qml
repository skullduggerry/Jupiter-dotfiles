pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string zoneWorkspaces: "workspaces"
    readonly property string zoneCalendar: "calendar"
    readonly property string zoneQuickSettings: "quicksettings"
    property string zone: root.zoneCalendar
    property bool visible: false
    // The screen it was opened on last, which goes null when unplugged; the
    // first screen until then.
    property ShellScreen picked: null
    readonly property ShellScreen screen: root.picked ?? Quickshell.screens[0] ?? null

    function open(zone: string, screen: ShellScreen) {
        if (screen !== null)
            root.picked = screen;

        root.zone = zone;
        root.visible = true;
    }

    function close() {
        root.visible = false;
    }

    function toggle(zone: string, screen: ShellScreen) {
        if (root.visible && root.zone === zone)
            root.close();
        else
            root.open(zone, screen);
    }

    // The arrow keys: the zones in the order they sit across the screen, with
    // no wrapping, since the ends are the edges of the screen.
    function step(direction: int) {
        const order = [root.zoneWorkspaces, root.zoneCalendar, root.zoneQuickSettings];
        const next = order.indexOf(root.zone) + direction;
        if (next >= 0 && next < order.length)
            root.zone = order[next];
    }

    function zoneAt(x: real, screen: ShellScreen): string {
        const offset = x - screen.x;
        if (offset < screen.width / 3)
            return root.zoneWorkspaces;

        if (offset < screen.width * 2 / 3)
            return root.zoneCalendar;

        return root.zoneQuickSettings;
    }

    function openAt(x: real, y: real) {
        const screen = Screens.at(x, y);
        if (screen === null) {
            console.warn("dropdown: no screen contains", x, y);
            return;
        }
        root.toggle(root.zoneAt(x, screen), screen);
    }
}
