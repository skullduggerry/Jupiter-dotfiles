pragma Singleton
pragma ComponentBehavior: Bound

import Qt.labs.folderlistmodel
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Images, notes and files to have on every device: a folder in the Nextcloud
// client's sync folder, so the client uploads what lands here and brings down
// what another device put there. Without the client it is a folder on this
// machine. The bar's ShelfWidget shows it; shelf.sh does the file work.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    // The client's first sync folder, from its own config.
    readonly property string syncFolder: {
        const match = clientConfig.text().match(/^\d+\\Folders(?:WithPlaceholders)?\\\d+\\localPath=(.+)$/m);
        return match ? match[1].replace(/\/+$/, "") : "";
    }
    readonly property bool synced: root.syncFolder !== ""
    readonly property string directory: root.synced ? root.syncFolder + "/Shelf" : (Quickshell.env("XDG_DATA_HOME") || root.home + "/.local/share") + "/shelf"
    readonly property string helper: Quickshell.shellDir + "/services/shelf.sh"
    // Newest first; the folder is watched, so what the client brings down
    // turns up by itself.
    readonly property FolderListModel files: FolderListModel {
        folder: maker.made === root.directory ? "file://" + root.directory : ""
        showDirs: false
        sortField: FolderListModel.Time
    }
    property string error: ""

    signal toggleRequested

    // From the shortcut, which has no list to show the result in: a toast.
    function paste(announce: bool) {
        if (paster.running)
            return;

        root.error = "";
        paster.announce = announce;
        paster.running = true;
    }

    function addNote(text: string) {
        if (text.trim() === "")
            return;

        root.error = "";
        Quickshell.execDetached([root.helper, "note", root.directory, text]);
    }

    function copy(path: string) {
        Quickshell.execDetached([root.helper, "copy", path]);
    }

    function open(path: string) {
        Session.app(["xdg-open", path]);
    }

    function remove(path: string) {
        Quickshell.execDetached(["rm", "-f", "--", path]);
    }

    onDirectoryChanged: maker.running = true

    GlobalShortcut {
        name: "shelfToggle"
        onPressed: root.toggleRequested()
    }

    GlobalShortcut {
        name: "shelfPaste"
        onPressed: root.paste(true)
    }

    FileView {
        id: clientConfig

        path: (Quickshell.env("XDG_CONFIG_HOME") || root.home + "/.config") + "/Nextcloud/nextcloud.cfg"
        // Read at once, so the folder is never first the one on this machine.
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: clientConfig.reload()
    }

    // A folder that does not exist yet cannot be watched.
    Process {
        id: maker

        property string made: ""

        running: true
        command: ["mkdir", "-p", root.directory]
        onExited: maker.made = root.directory
    }

    Process {
        id: paster

        property bool announce: false
        property string added: ""

        command: [root.helper, "paste", root.directory]
        onStarted: paster.added = ""
        onExited: (exitCode, exitStatus) => {
            const message = exitCode === 0 ? "" : exitCode === 1 ? "Nothing to paste" : exitCode === 3 ? "Passwords stay off the shelf" : "Could not paste onto the shelf";
            root.error = message;
            if (paster.announce)
                Quickshell.execDetached(["notify-send", "--app-name=Shelf", "--icon=edit-paste", message === "" ? "On the shelf" : message, paster.added]);
        }

        stdout: SplitParser {
            onRead: line => {
                paster.added = paster.added === "" ? line : paster.added + ", " + line;
            }
        }
    }
}
