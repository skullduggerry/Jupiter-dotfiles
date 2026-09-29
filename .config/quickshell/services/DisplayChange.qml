pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// A monitor change from the Displays page, applied and then kept or taken back
// (settings/displays.py). It goes back by itself unless kept in time, since a
// mode the screen cannot show leaves nothing to click, window closed or not.
Singleton {
    id: root

    readonly property string helper: Quickshell.shellDir + "/settings/displays.py"
    readonly property int keepSeconds: 15
    // hl.monitor rules: the ones applied, and the ones that undo them.
    property var appliedRules: null
    property var revertRules: null
    property int secondsLeft: 0
    readonly property bool waiting: root.appliedRules !== null
    property string error: ""

    // The monitors changed; whoever shows them reads them again.
    signal settled

    function apply(rules, previous) {
        if (root.waiting || rules.length === 0)
            return;

        root.error = "";
        root.appliedRules = rules;
        root.revertRules = previous;
        root.secondsLeft = root.keepSeconds;
        applier.command = ["python3", root.helper, "apply", JSON.stringify(rules)];
        applier.running = true;
    }

    function keep() {
        if (!root.waiting)
            return;

        saver.command = ["python3", root.helper, "save", JSON.stringify(root.appliedRules)];
        saver.running = true;
        root.appliedRules = null;
        root.revertRules = null;
        root.settled();
    }

    function revert() {
        if (!root.waiting)
            return;

        applier.command = ["python3", root.helper, "apply", JSON.stringify(root.revertRules)];
        applier.running = true;
        root.appliedRules = null;
        root.revertRules = null;
    }

    // A kept output back to what the Hyprland config says: dropped from the
    // saved rules, then a config reload, the only way to lose a runtime rule.
    function forget(output: string) {
        forgetter.command = ["sh", "-c", "python3 \"$1\" forget \"$2\" && hyprctl reload", "sh", root.helper, output];
        forgetter.running = true;
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.waiting
        onTriggered: {
            root.secondsLeft -= 1;
            if (root.secondsLeft <= 0)
                root.revert();
        }
    }

    Process {
        id: applier

        onExited: exitCode => {
            // A rule Hyprland refused: go straight back, nothing to wait for.
            if (exitCode !== 0 && root.waiting)
                root.revert();

            root.settled();
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    root.error = text.trim();
            }
        }
    }

    Process {
        id: saver

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    root.error = text.trim();
            }
        }
    }

    Process {
        id: forgetter

        onExited: root.settled()
    }
}
