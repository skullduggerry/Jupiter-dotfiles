pragma ComponentBehavior: Bound

import "../panels"
import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Io

// The lock and login screens: a background each, one style for both
// (LockLook). The lock screen follows at once; the login screen runs as
// another user from a copy in /etc/greetd, which Apply reinstalls through
// pkexec (scripts/install-greeter.sh) and which says what it was made from.
ScrollPage {
    id: root

    readonly property var backgroundChoices: [
        {
            label: "Wallpaper",
            value: "wallpaper"
        },
        {
            label: "Image",
            value: "image"
        },
        {
            label: "Plain",
            value: "plain"
        }
    ]
    readonly property string lockSource: root.sourceFor(LockLook.lockBackground, LockLook.lockImage, WallpaperService.current)
    // The installer takes the desktop's pick for every workspace.
    readonly property string loginSource: root.sourceFor(LockLook.loginBackground, LockLook.loginImage, WallpaperService.allWorkspaces)
    readonly property var installed: {
        try {
            return JSON.parse(installedFile.text());
        } catch (error) {
            return null;
        }
    }
    readonly property bool loginCurrent: root.installed !== null && root.installed.installedImage === root.loginSource && root.installed.loginBackground === LockLook.loginBackground && root.installed.blur === LockLook.blur && root.installed.dim === LockLook.dim && root.installed.clock === LockLook.clock
    property string installError: ""

    function sourceFor(background: string, image: string, wallpaper: string): string {
        return background === "image" ? image : background === "wallpaper" ? wallpaper : "";
    }

    function choose(key: string) {
        chooser.key = key;
        chooser.running = true;
    }

    // A background's choice, and with Image the file it shows.
    component BackgroundRows: Column {
        id: rows

        required property string backgroundKey
        required property string imageKey
        readonly property string image: LockLook[rows.imageKey]

        width: parent.width
        spacing: Style.bar.spacing

        FormRow {
            label: "Background"

            PillGroup {
                choices: root.backgroundChoices
                current: LockLook[rows.backgroundKey]
                onPicked: value => {
                    if (value === "image" && rows.image === "")
                        root.choose(rows.imageKey);
                    else
                        LockLook.set(rows.backgroundKey, value);
                }
            }
        }

        FormRow {
            visible: LockLook[rows.backgroundKey] === "image"
            label: "Image"

            Row {
                width: parent.width
                spacing: Style.bar.spacing

                PillButton {
                    id: chooseButton

                    text: "Choose…"
                    action: true
                    onClicked: root.choose(rows.imageKey)
                }

                Text {
                    width: parent.width - chooseButton.width - Style.bar.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    text: rows.image.split("/").pop()
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                    elide: Text.ElideMiddle
                }
            }
        }
    }

    FileView {
        id: installedFile

        path: "/etc/greetd/quickshell/lockscreen.json"
        printErrors: false
        watchChanges: true
        onFileChanged: installedFile.reload()
    }

    // An image picked for one background, which then shows it.
    Process {
        id: chooser

        property string key: ""

        command: ["zenity", "--file-selection", "--title=Choose a background", "--filename=" + Quickshell.env("HOME") + "/Wallpapers/", "--file-filter=Images | *.jpg *.jpeg *.png *.webp *.bmp *.JPG *.JPEG *.PNG *.WEBP *.BMP"]

        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                if (path === "")
                    return;

                LockLook.set(chooser.key, path);
                LockLook.set(chooser.key === "lockImage" ? "lockBackground" : "loginBackground", "image");
            }
        }
    }

    // The installer's path resolved first: ~/.config/quickshell is a link,
    // and pkexec names the program it asks about.
    Process {
        id: installer

        command: ["sh", "-c", "exec pkexec \"$(readlink -f \"$1\")\"", "sh", Quickshell.shellDir + "/../../scripts/install-greeter.sh"]
        onStarted: root.installError = ""
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 126)
                root.installError = "Cancelled";
            else if (exitCode !== 0)
                root.installError = "Could not install the login screen";
            installedFile.reload();
        }
    }

    Row {
        width: root.columnWidth
        spacing: Style.settings.spacing

        LockPreview {
            width: (parent.width - Style.settings.spacing) / 2
            title: "Lock screen"
            source: root.lockSource
        }

        LockPreview {
            width: (parent.width - Style.settings.spacing) / 2
            title: "Login screen"
            source: root.loginSource
        }
    }

    Section {
        title: "LOCK SCREEN"

        FormCard {
            width: root.columnWidth

            BackgroundRows {
                backgroundKey: "lockBackground"
                imageKey: "lockImage"
            }
        }
    }

    Section {
        title: "LOGIN SCREEN"

        FormCard {
            width: root.columnWidth

            BackgroundRows {
                backgroundKey: "loginBackground"
                imageKey: "loginImage"
            }

            ActionRow {
                width: parent.width
                text: installer.running ? "Installing…" : root.installError !== "" ? root.installError : root.loginCurrent ? "Up to date" : "Not applied yet: the login screen keeps a copy"
                action: "Apply"
                onActivated: {
                    if (!installer.running)
                        installer.running = true;
                }
            }
        }
    }

    Section {
        title: "STYLE"

        FormCard {
            width: root.columnWidth

            FormRow {
                label: "Blur"

                PillGroup {
                    choices: [
                        {
                            label: "While typing",
                            value: "typing"
                        },
                        {
                            label: "Always",
                            value: "always"
                        },
                        {
                            label: "Off",
                            value: "off"
                        }
                    ]
                    current: LockLook.blur
                    onPicked: value => LockLook.set("blur", value)
                }
            }

            FormRow {
                label: "Dim"

                Row {
                    width: parent.width
                    height: Style.popup.itemHeight
                    spacing: Style.widgets.spacing

                    PanelSlider {
                        width: parent.width - Style.settings.labelWidth - Style.widgets.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        value: LockLook.dim / Style.lock.dimMost
                        onMoved: position => LockLook.set("dim", Math.round(position * Style.lock.dimMost * 20) / 20)
                    }

                    Text {
                        width: Style.settings.labelWidth
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(LockLook.dim * 100) + "%"
                        color: Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.smallSize
                    }
                }
            }

            FormRow {
                label: "Clock"

                PillGroup {
                    current: LockLook.clock
                    onPicked: value => LockLook.set("clock", value)
                }
            }
        }
    }
}
