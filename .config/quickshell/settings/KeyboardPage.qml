pragma ComponentBehavior: Bound

import "../icons"
import "../panels"
import "../services"
import "../style"
import QtQuick
import Quickshell.Io

// The keyboard layouts SUPER+SPACE and the bar's keyboard switch between, kept
// on this machine (KeyboardLayout.setLayouts). A click picks the one in use, a
// login starts on the first. Names and what can be added come from XKB's own
// list, the one Hyprland's documentation points to.
ScrollPage {
    id: root

    // Every layout and variant XKB has: {layout, variant, name}, by name.
    property var catalogue: []
    property bool adding: false
    readonly property var candidates: {
        if (!root.adding)
            return [];

        const query = layoutSearch.text.trim().toLowerCase();
        return root.catalogue.filter(entry => root.position(entry.layout, entry.variant) < 0 && (query === "" || entry.name.toLowerCase().includes(query) || root.spelled(entry).toLowerCase().startsWith(query)));
    }

    function position(code: string, variant: string): int {
        return KeyboardLayout.codes.findIndex((candidate, index) => candidate === code && KeyboardLayout.variants[index] === variant);
    }

    // As XKB writes it: "de(nodeadkeys)".
    function spelled(entry): string {
        return entry.variant !== "" ? `${entry.layout}(${entry.variant})` : entry.layout;
    }

    function nameOf(code: string, variant: string): string {
        const entry = root.catalogue.find(candidate => candidate.layout === code && candidate.variant === variant);
        return entry !== undefined ? entry.name : root.spelled({
            layout: code,
            variant: variant
        });
    }

    // base.lst lists "<code>  <name>" under "! layout", and "<code>  <layout>:
    // <name>" under "! variant".
    function parse(text: string): var {
        const entries = [];
        let section = "";
        for (const line of text.split("\n")) {
            if (line.startsWith("! ")) {
                section = line.slice(2).trim();
                continue;
            }
            const fields = /^\s+(\S+)\s+(.+)$/.exec(line);
            if (fields === null)
                continue;

            if (section === "layout")
                entries.push({
                    layout: fields[1],
                    variant: "",
                    name: fields[2]
                });

            const variant = section === "variant" ? /^(\S+):\s+(.+)$/.exec(fields[2]) : null;
            if (variant !== null)
                entries.push({
                    layout: variant[1],
                    variant: fields[1],
                    name: variant[2]
                });
        }
        return entries.sort((left, right) => left.name.localeCompare(right.name));
    }

    function add(entry) {
        root.adding = false;
        KeyboardLayout.setLayouts([...KeyboardLayout.codes, entry.layout], [...KeyboardLayout.variants, entry.variant]);
    }

    function remove(index: int) {
        KeyboardLayout.setLayouts(KeyboardLayout.codes.filter((code, position) => position !== index), KeyboardLayout.variants.filter((variant, position) => position !== index));
    }

    // One place up; the first is the one a login starts on.
    function raise(index: int) {
        const codes = Array.from(KeyboardLayout.codes);
        const variants = Array.from(KeyboardLayout.variants);
        codes.splice(index - 1, 0, ...codes.splice(index, 1));
        variants.splice(index - 1, 0, ...variants.splice(index, 1));
        KeyboardLayout.setLayouts(codes, variants);
    }

    FileView {
        path: "/usr/share/X11/xkb/rules/base.lst"
        onLoaded: root.catalogue = root.parse(text())
    }

    Section {
        title: "LAYOUTS"

        Card {
            width: root.columnWidth
            height: layoutRows.implicitHeight + Style.bar.padding * 2

            Column {
                id: layoutRows

                spacing: Style.widgets.spacing

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: Style.bar.padding
                }

                Repeater {
                    model: KeyboardLayout.codes

                    delegate: Rectangle {
                        id: layout

                        required property string modelData
                        required property int index
                        readonly property bool inUse: layout.index === KeyboardLayout.index

                        width: layoutRows.width
                        height: Style.settings.itemHeight
                        radius: Style.popup.rowRadius
                        color: layoutArea.containsMouse && !layout.inUse ? Colors.base.hover : "transparent"

                        Icon {
                            id: radio

                            text: layout.inUse ? Icons.circleDot : Icons.circle
                            color: layout.inUse ? Colors.accent.primary : Colors.text.muted
                            font.pixelSize: Style.text.size

                            anchors {
                                left: parent.left
                                leftMargin: Style.widgets.padding
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            text: root.nameOf(layout.modelData, KeyboardLayout.variants[layout.index] ?? "")
                            color: layout.inUse ? Colors.text.base : Colors.text.muted
                            font.family: Style.text.font
                            font.pixelSize: Style.text.size
                            elide: Text.ElideRight

                            anchors {
                                left: radio.right
                                right: controls.left
                                leftMargin: Style.bar.spacing
                                rightMargin: Style.bar.spacing
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: layoutArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: layout.inUse ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked: {
                                if (!layout.inUse)
                                    KeyboardLayout.select(layout.index);
                            }
                        }

                        Row {
                            id: controls

                            spacing: Style.bar.spacing

                            anchors {
                                right: parent.right
                                rightMargin: Style.widgets.padding
                                verticalCenter: parent.verticalCenter
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: KeyboardLayout.layouts[layout.index] ?? ""
                                color: Colors.text.muted
                                font.family: Style.text.font
                                font.pixelSize: Style.text.smallSize
                            }

                            TextButton {
                                visible: layout.index > 0
                                anchors.verticalCenter: parent.verticalCenter
                                text: Icons.chevronUp
                                font.family: Icons.font
                                font.pixelSize: Style.text.size
                                onClicked: root.raise(layout.index)
                            }

                            TextButton {
                                visible: KeyboardLayout.codes.length > 1
                                anchors.verticalCenter: parent.verticalCenter
                                text: Icons.x
                                font.family: Icons.font
                                font.pixelSize: Style.text.size
                                onClicked: root.remove(layout.index)
                            }
                        }
                    }
                }

                Text {
                    visible: KeyboardLayout.codes.length === 0
                    text: "No keyboard"
                    color: Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                }
            }
        }

        ActionRow {
            width: root.columnWidth
            text: "SUPER+SPACE switches, and a login starts on the first"
            action: root.adding ? "Cancel" : "Add layout…"
            onActivated: {
                root.adding = !root.adding;
                layoutSearch.text = "";
                if (root.adding)
                    layoutSearch.focusInput();
            }
        }

        InputField {
            id: layoutSearch

            visible: root.adding
            width: root.columnWidth
            placeholder: "Search layouts…"
            icon: Icons.search
            onAccepted: {
                if (root.candidates.length > 0)
                    root.add(root.candidates[0]);
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

                    required property var modelData

                    width: candidateList.width
                    height: Style.popup.itemHeight
                    radius: Style.popup.rowRadius
                    color: candidateArea.containsMouse ? Colors.base.hover : "transparent"

                    Text {
                        text: candidate.modelData.name
                        color: Colors.text.base
                        font.family: Style.text.font
                        font.pixelSize: Style.text.size
                        elide: Text.ElideRight

                        anchors {
                            left: parent.left
                            right: spelling.left
                            leftMargin: Style.widgets.padding
                            rightMargin: Style.bar.spacing
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        id: spelling

                        text: root.spelled(candidate.modelData)
                        color: Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.smallSize

                        anchors {
                            right: parent.right
                            rightMargin: Style.widgets.padding
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: candidateArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.add(candidate.modelData)
                    }
                }
            }
        }
    }
}
