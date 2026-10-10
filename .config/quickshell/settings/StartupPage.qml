import "../icons"
import "../panels"
import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

// What starts with the session. Hyprland's own list is read from its config
// (hypr/modules/startup.lua) with plain lua, the way Hyprland reads it, and
// is edited there. The apps are XDG autostart, which uwsm hands to systemd;
// autostart.py lists them as systemd decides and switches them on and off.
ScrollPage {
    id: root

    readonly property string hyprDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/hypr"
    readonly property string helper: Quickshell.shellDir + "/settings/autostart.py"
    property var session: []
    property string sessionError: ""
    property var apps: []
    property bool adding: false
    // Installed apps not starting already, for "Add app…".
    readonly property var candidates: {
        if (!root.adding)
            return [];

        const query = appSearch.text.trim().toLowerCase();
        const taken = root.apps.map(app => app.id);
        return Array.from(DesktopEntries.applications.values).filter(entry => !entry.noDisplay && entry.name !== "" && !taken.includes(entry.id) && (query === "" || entry.name.toLowerCase().includes(query))).sort((left, right) => left.name.localeCompare(right.name));
    }

    function change(args) {
        changer.command = ["python3", root.helper].concat(args);
        changer.running = true;
    }

    function stateText(app): string {
        if (!app.enabled)
            return app.state === "running" ? "Off from the next login" : "";

        switch (app.state) {
        case "running":
            return "Running";
        case "failed":
            return "Failed to start";
        case "":
            return "From the next login";
        default:
            return "Not running";
        }
    }

    maximumWidth: Style.settings.listWidth
    Component.onCompleted: {
        sessionReader.running = true;
        appLister.running = true;
    }

    Process {
        id: sessionReader

        command: ["lua", Quickshell.shellDir + "/settings/startup-list.lua", root.hyprDir]

        stdout: StdioCollector {
            onStreamFinished: root.session = text.split("\n").filter(line => line !== "").map(line => {
                const fields = line.split("\t");
                return {
                    name: fields[0],
                    command: fields[1] || "",
                    about: fields[2] || ""
                };
            })
        }

        stderr: StdioCollector {
            onStreamFinished: root.sessionError = text.split("\n")[0]
        }
    }

    Process {
        id: appLister

        command: ["python3", root.helper, "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.apps = JSON.parse(text);
                } catch (error) {
                    console.warn("startup: autostart.py printed no list:", error);
                }
            }
        }
    }

    Process {
        id: changer

        onExited: appLister.running = true

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    console.warn("startup:", text.trim());
            }
        }
    }

    Section {
        title: "STARTED BY HYPRLAND"

        Card {
            width: root.columnWidth
            height: sessionRows.implicitHeight + Style.bar.padding * 2

            Column {
                id: sessionRows

                spacing: Style.bar.spacing

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: Style.bar.padding
                }

                Repeater {
                    model: root.session

                    delegate: Item {
                        id: entry

                        required property var modelData

                        width: sessionRows.width
                        height: entryText.implicitHeight

                        Column {
                            id: entryText

                            spacing: Style.widgets.spacing

                            anchors {
                                left: parent.left
                                right: command.left
                                rightMargin: Style.bar.spacing
                            }

                            Text {
                                width: parent.width
                                text: entry.modelData.name
                                color: Colors.text.base
                                font.family: Style.text.font
                                font.pixelSize: Style.text.size
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: entry.modelData.about
                                color: Colors.text.muted
                                font.family: Style.text.font
                                font.pixelSize: Style.text.smallSize
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            id: command

                            width: Math.min(implicitWidth, entry.width * Style.settings.detailShare)
                            text: entry.modelData.command
                            color: Colors.text.muted
                            font.family: Style.text.font
                            font.pixelSize: Style.text.smallSize
                            elide: Text.ElideMiddle
                            horizontalAlignment: Text.AlignRight

                            anchors {
                                right: parent.right
                                top: parent.top
                            }
                        }
                    }
                }

                Text {
                    visible: root.session.length === 0
                    width: parent.width
                    text: root.sessionError !== "" ? root.sessionError : "Reading Hyprland's config…"
                    color: root.sessionError !== "" ? Colors.status.error : Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                    wrapMode: Text.Wrap
                }
            }
        }

        ActionRow {
            width: root.columnWidth
            text: "Edited in hypr/modules/startup.lua"
            action: "Edit startup.lua"
            onActivated: Session.app(["xdg-open", root.hyprDir + "/modules/startup.lua"])
        }
    }

    Section {
        title: "APPS"

        Card {
            width: root.columnWidth
            height: appRows.implicitHeight + Style.bar.padding * 2

            Column {
                id: appRows

                spacing: Style.bar.spacing

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: Style.bar.padding
                }

                Repeater {
                    model: root.apps

                    delegate: Item {
                        id: app

                        required property var modelData

                        width: appRows.width
                        height: Math.max(appText.implicitHeight, Style.popup.itemHeight)

                        IconImage {
                            id: appIcon

                            implicitSize: Style.settings.appIconSize
                            source: Quickshell.iconPath(app.modelData.icon, "application-x-executable")

                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        Column {
                            id: appText

                            spacing: Style.widgets.spacing

                            anchors {
                                left: appIcon.right
                                right: controls.left
                                leftMargin: Style.bar.spacing
                                rightMargin: Style.bar.spacing
                                verticalCenter: parent.verticalCenter
                            }

                            Text {
                                width: parent.width
                                text: app.modelData.name
                                textFormat: Text.PlainText
                                color: app.modelData.enabled ? Colors.text.base : Colors.text.muted
                                font.family: Style.text.font
                                font.pixelSize: Style.text.size
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: app.modelData.comment !== "" ? app.modelData.comment : app.modelData.exec
                                textFormat: Text.PlainText
                                color: Colors.text.muted
                                font.family: Style.text.font
                                font.pixelSize: Style.text.smallSize
                                elide: Text.ElideRight
                            }
                        }

                        Row {
                            id: controls

                            spacing: Style.bar.spacing

                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.stateText(app.modelData)
                                color: app.modelData.state === "failed" ? Colors.status.error : Colors.text.muted
                                font.family: Style.text.font
                                font.pixelSize: Style.text.smallSize
                            }

                            PillButton {
                                width: Style.settings.switchWidth
                                text: app.modelData.enabled ? "On" : "Off"
                                checked: app.modelData.enabled
                                compact: true
                                onClicked: root.change(["set", app.modelData.id, app.modelData.enabled ? "off" : "on"])
                            }

                            // Only for an entry the user's folder alone has; a
                            // system one is switched off instead.
                            TextButton {
                                visible: app.modelData.custom
                                anchors.verticalCenter: parent.verticalCenter
                                text: Icons.x
                                font.family: Icons.font
                                font.pixelSize: Style.text.size
                                onClicked: root.change(["remove", app.modelData.id])
                            }
                        }
                    }
                }

                Text {
                    visible: root.apps.length === 0
                    text: "No app starts with the session"
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                }
            }
        }

        ActionRow {
            width: root.columnWidth
            text: "Changes take effect at the next login"
            action: root.adding ? "Cancel" : "Add app…"
            onActivated: {
                root.adding = !root.adding;
                appSearch.text = "";
                if (root.adding)
                    appSearch.focusInput();
            }
        }

        InputField {
            id: appSearch

            visible: root.adding
            width: root.columnWidth
            placeholder: "Search apps…"
            icon: Icons.search
            onAccepted: {
                if (root.candidates.length > 0) {
                    root.change(["add", root.candidates[0].id]);
                    root.adding = false;
                }
            }
        }

        Card {
            visible: root.adding
            width: root.columnWidth
            height: Style.settings.listHeight

            ListView {
                id: candidateList

                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.candidates

                anchors {
                    fill: parent
                    margins: Style.widgets.padding
                }

                delegate: Rectangle {
                    id: candidate

                    required property DesktopEntry modelData

                    width: candidateList.width
                    height: Style.popup.itemHeight
                    radius: Style.popup.rowRadius
                    color: candidateArea.containsMouse ? Colors.base.hover : "transparent"

                    IconImage {
                        id: candidateIcon

                        implicitSize: Style.text.largeSize
                        source: Quickshell.iconPath(candidate.modelData.icon, "application-x-executable")

                        anchors {
                            left: parent.left
                            leftMargin: Style.widgets.padding
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        text: candidate.modelData.name
                        textFormat: Text.PlainText
                        color: Colors.text.base
                        font.family: Style.text.font
                        font.pixelSize: Style.text.size
                        elide: Text.ElideRight

                        anchors {
                            left: candidateIcon.right
                            right: parent.right
                            leftMargin: Style.bar.spacing
                            rightMargin: Style.widgets.padding
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: candidateArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.change(["add", candidate.modelData.id]);
                            root.adding = false;
                        }
                    }
                }
            }
        }
    }
}
