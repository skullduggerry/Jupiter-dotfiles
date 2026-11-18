pragma Singleton

import QtQuick
import Quickshell

// How the shell starts apps and ends the session, the way
// .config/hypr/modules/session.lua does for Hyprland's binds: under uwsm, each
// app in a systemd scope of its own (uwsm-app), as the Hyprland wiki asks,
// rather than in the shell's, and logging out through `uwsm stop`.
Singleton {
    id: root

    readonly property bool uwsm: (Quickshell.env("UWSM_FINALIZE_VARNAMES") ?? "") !== ""

    function app(command: list<string>) {
        Quickshell.execDetached(root.uwsm ? ["uwsm-app", "--"].concat(Array.from(command)) : command);
    }

    // By its desktop file id, so uwsm runs it as the entry says (Terminal,
    // Path), which execute() does not.
    function entry(desktopEntry: DesktopEntry) {
        if (root.uwsm)
            Quickshell.execDetached(["uwsm-app", "--", desktopEntry.id + ".desktop"]);
        else
            desktopEntry.execute();
    }

    function logout() {
        Quickshell.execDetached(["hyprctl", "eval", "require(\"modules.session\").logout()"]);
    }

    // The bar's power menu and the quick menu's, alike.
    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function poweroff() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }
}
