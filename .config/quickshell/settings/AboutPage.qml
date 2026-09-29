import "../panels"
import "../style"
import QtQuick
import Quickshell.Io

// What this machine is, then the usage dropdown's details, which read the CPU
// every second for as long as the page is open.
Item {
    id: root

    readonly property int columnWidth: Math.min(Style.settings.pageWidth, root.width - Style.settings.padding * 2)
    readonly property string system: {
        const match = /^PRETTY_NAME="?([^"\n]*)"?$/m.exec(osRelease.text());
        return match === null ? "" : match[1];
    }
    property string hyprland: ""
    property string quickshell: ""

    Section {
        id: facts

        title: "SYSTEM"

        anchors {
            top: parent.top
            left: parent.left
            leftMargin: Style.settings.padding
        }

        DetailRow {
            width: root.columnWidth
            label: "Host"
            value: hostname.text().trim()
        }

        DetailRow {
            width: root.columnWidth
            label: "System"
            value: root.system
        }

        DetailRow {
            width: root.columnWidth
            label: "Kernel"
            value: kernel.text().trim()
        }

        DetailRow {
            width: root.columnWidth
            label: "Hyprland"
            value: root.hyprland
        }

        DetailRow {
            width: root.columnWidth
            label: "Quickshell"
            value: root.quickshell
        }
    }

    PanelCard {
        preferredHeight: usage.implicitHeight

        anchors {
            top: facts.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            topMargin: Style.settings.spacing
        }

        SystemPanel {
            id: usage

            anchors.fill: parent
        }
    }

    FileView {
        id: hostname

        path: "/proc/sys/kernel/hostname"
        blockLoading: true
    }

    FileView {
        id: kernel

        path: "/proc/sys/kernel/osrelease"
        blockLoading: true
    }

    FileView {
        id: osRelease

        path: "/etc/os-release"
        blockLoading: true
    }

    Process {
        running: true
        command: ["hyprctl", "version", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.hyprland = JSON.parse(text).version;
                } catch (error) {
                    console.warn("about: hyprctl printed no version:", error);
                }
            }
        }
    }

    Process {
        running: true
        command: ["qs", "--version"]

        stdout: StdioCollector {
            onStreamFinished: root.quickshell = text.replace(/^Quickshell /, "").split(" ")[0]
        }
    }
}
