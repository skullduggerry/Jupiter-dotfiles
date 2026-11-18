import "../services"
import QtQuick
import Quickshell
import Quickshell.Io

// What cliphist holds, newest first, for ClipboardPanel and the quick menu's
// list: read while `active`, and again whenever the database changes.
Scope {
    id: root

    required property bool active
    // cliphist's own lines, "<id>\t<preview>", which decode and delete take back.
    property list<string> entries: []
    // What a list of them says while it has none.
    readonly property string emptyText: QuickToggles.clipboardHistory ? "Nothing copied yet" : "History is off"

    function refresh() {
        if (lister.running)
            lister.stale = true;
        else
            lister.running = true;
    }

    // cliphist previews an image as "[[ binary data 13 KiB png 120x120 ]]".
    function label(line: string): string {
        const preview = line.slice(line.indexOf("\t") + 1);
        const image = preview.match(/^\[\[ binary data .+ (\w+) (\d+)x(\d+) \]\]$/);
        return image ? `${image[1].toUpperCase()} image, ${image[2]}×${image[3]}` : preview;
    }

    // The line goes to cliphist on stdin, never through a shell's quoting.
    // A copy while one runs goes after it, the last asked for winning.
    function copy(line: string) {
        copier.line = line;
        copier.running = true;
    }

    // Lines forgotten while a delete runs go together in the next.
    function forget(line: string) {
        forgetter.waiting.push(line);
        forgetter.next();
    }

    function wipe() {
        wiper.running = true;
    }

    function setEnabled(enabled: bool) {
        QuickToggles.setClipboardHistory(enabled);
        root.refresh();
    }

    onActiveChanged: {
        if (root.active)
            root.refresh();
    }
    // Built shown, as the quick menu builds its list.
    Component.onCompleted: {
        if (root.active)
            root.refresh();
    }

    // cliphist's database, watched (never read) while shown, so the list
    // follows copies made meanwhile; re-armed at every showing, which also
    // catches a database created since.
    FileView {
        path: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/cliphist/db"
        preload: false
        printErrors: false
        watchChanges: root.active
        onFileChanged: root.refresh()
    }

    Process {
        id: lister

        // A change that came in during a read: read once more afterwards.
        property bool stale: false

        command: ["cliphist", "list"]
        onRunningChanged: {
            if (!lister.running && lister.stale) {
                lister.stale = false;
                lister.running = true;
            }
        }

        stdout: StdioCollector {
            onStreamFinished: root.entries = text.split("\n").filter(line => line.includes("\t"))
        }
    }

    Process {
        id: copier

        property string line: ""

        command: ["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "sh", copier.line]
    }

    Process {
        id: forgetter

        property list<string> lines: []
        property list<string> waiting: []

        function next() {
            if (forgetter.running || forgetter.waiting.length === 0)
                return;
            forgetter.lines = forgetter.waiting;
            forgetter.waiting = [];
            forgetter.running = true;
        }

        command: ["sh", "-c", "printf '%s\\n' \"$@\" | cliphist delete", "sh", ...forgetter.lines]
        onRunningChanged: {
            if (forgetter.running)
                return;
            if (forgetter.waiting.length > 0)
                forgetter.next();
            else
                root.refresh();
        }
    }

    Process {
        id: wiper

        command: ["cliphist", "wipe"]
        onExited: root.refresh()
    }
}
