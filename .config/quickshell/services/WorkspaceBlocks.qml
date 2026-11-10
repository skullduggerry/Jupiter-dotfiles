pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Every monitor numbers its own workspaces: .config/hypr/modules/workspaces.lua
// gives each one a block of 100 ids, by output name, and records them here.
Singleton {
    id: root

    readonly property int idsPerMonitor: 100
    readonly property var blocks: blockMap.blocks

    // -1 until the file names the monitor.
    function blockOf(monitor: string): int {
        const block = root.blocks[monitor];
        return block === undefined ? -1 : block;
    }

    // The number the keys go by.
    function number(workspace: HyprlandWorkspace): int {
        return workspace.id % root.idsPerMonitor;
    }

    // What a special workspace is called: "special:magic" is "magic", which
    // fits a tile where the whole of it was cut off after "specia".
    function specialName(name: string): string {
        return name.replace(/^special:/, "");
    }

    // "DP-2:3": the same workspace in every session, where its id is not. A
    // special workspace has none.
    function key(workspace: HyprlandWorkspace): string {
        if (workspace === null || workspace.id <= 0)
            return "";

        const block = Math.floor(workspace.id / root.idsPerMonitor);
        const owner = Object.keys(root.blocks).find(name => root.blocks[name] === block);
        return owner === undefined ? workspace.name : owner + ":" + root.number(workspace);
    }

    // Held by this monitor for one that is unplugged.
    function parked(workspace: HyprlandWorkspace, monitor: string): bool {
        const block = root.blockOf(monitor);
        return workspace.id > 0 && block !== -1 && Math.floor(workspace.id / root.idsPerMonitor) !== block;
    }

    FileView {
        id: blocksFile

        path: Quickshell.env("XDG_RUNTIME_DIR") + "/hypr/" + Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") + "/workspace-blocks.json"
        watchChanges: true
        printErrors: false
        onFileChanged: blocksFile.reload()

        adapter: JsonAdapter {
            id: blockMap

            property var blocks: ({})
        }
    }
}
