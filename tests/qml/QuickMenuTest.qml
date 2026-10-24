import QtQuick
import Quickshell
import Quickshell.Io
import "../../.config/quickshell/services"

// The quick menu's look, which the pencil's panel picks: kept in its file,
// and Auto for anything it does not know, as a file from before the choice
// existed, or one edited by hand, would have.
TestCase {
    readonly property FileView written: FileView {
        path: Quickshell.statePath("quick-menu.json")
        blockLoading: true
        printErrors: false
    }

    function stored(): var {
        written.reload();
        return JSON.parse(written.text() || "{}");
    }

    function test_aLookIsKept() {
        compare(QuickMenu.look, "auto", "the look before one is picked");
        QuickMenu.setLook("orbit");
        compare(QuickMenu.look, "orbit");
        return tryVerify(() => stored().look === "orbit", 2000, "the look is written").then(() => {
            QuickMenu.setLook("halo");
            compare(QuickMenu.look, "halo");
        });
    }

    function test_anUnknownLookIsAuto() {
        QuickMenu.setLook("sparkly");
        compare(QuickMenu.look, "auto");
    }
}
