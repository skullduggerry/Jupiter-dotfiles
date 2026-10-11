pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The apps on offer (the launcher, Settings' Startup tab): the desktop
// entries whose program is there. An app may write its own copy of its entry
// into ~/.local/share/applications, which outlives the package (Claude's
// does), and Quickshell ignores TryExec, so each entry's program is looked
// up on PATH. Until the lookup answers, nothing is left out.
Singleton {
    id: root

    property list<string> missing: []
    readonly property var installed: DesktopEntries.applications.values.filter(entry => entry.name !== "" && !root.missing.includes(root.program(entry)))

    function program(entry: DesktopEntry): string {
        return entry.command.length > 0 ? entry.command[0] : "";
    }

    // Run when a list of apps opens, as removing a package changes no entry.
    function check() {
        const programs = [...new Set(DesktopEntries.applications.values.map(root.program).filter(program => program !== ""))];
        lookup.command = ["sh", "-c", "for program; do command -v -- \"$program\" >/dev/null || printf '%s\\n' \"$program\"; done", "sh"].concat(programs);
        lookup.running = true;
    }

    Connections {
        function onApplicationsChanged() {
            root.check();
        }

        target: DesktopEntries
    }

    Process {
        id: lookup

        stdout: StdioCollector {
            onStreamFinished: root.missing = text.split("\n").filter(line => line !== "")
        }
    }
}
