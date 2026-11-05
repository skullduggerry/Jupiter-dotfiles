pragma ComponentBehavior: Bound

import "../icons"
import "../panels"
import "../services"
import "../style"
import QtQuick

// The overlay's panel: Hyprland's binds (services/Keybinds) in sections, in as
// many columns as fit, and under them the keyboard in the layout in use with
// the selected bind's keys lit. The pointer and the arrows select. A search
// and a key under the pointer fade the binds that do not match, leaving the
// layout as it is; a search selects its first match.
Rectangle {
    id: root

    property real maximumWidth: 0
    property real maximumHeight: 0
    // A bind goes to the first of these with one of its words in the bind's
    // description, else to GENERAL, and one on keys only a keyboard's extras
    // have (XF86…) to HARDWARE KEYS. They show in the order the config first
    // has one.
    readonly property var sectionWords: [
        {
            title: "WORKSPACES",
            words: ["workspace", "scratchpad"]
        },
        {
            title: "MONITORS",
            words: ["monitor"]
        },
        {
            title: "SCREENSHOTS",
            words: ["screenshot"]
        },
        {
            title: "WINDOWS",
            words: ["window", "split"]
        }
    ]
    readonly property var sections: {
        const sections = [];
        for (const row of Keybinds.rows) {
            const title = root.sectionOf(row);
            let section = sections.find(candidate => candidate.title === title);
            if (section === undefined) {
                section = {
                    title: title,
                    rows: []
                };
                sections.push(section);
            }
            section.rows.push(row);
        }
        return sections;
    }
    readonly property int columnCount: Math.max(1, Math.min(Style.shortcuts.columns, Math.floor((root.maximumWidth - Style.bar.padding * 2 + Style.settings.padding) / (Style.shortcuts.columnWidth + Style.settings.padding))))
    // Each section goes into the column shortest so far, counted in rows.
    readonly property var columns: {
        const columns = Array.from({
            length: root.columnCount
        }, () => ({
                    sections: [],
                    rows: 0
                }));
        for (const section of root.sections) {
            const shortest = columns.reduce((best, column) => column.rows < best.rows ? column : best);
            shortest.sections.push(section);
            shortest.rows += section.rows.length + 1;
        }
        return columns.map(column => column.sections);
    }
    // Rows go by their index from here on: delegates hold copies of them.
    readonly property string query: search.text.trim().toLowerCase()
    readonly property list<int> matches: Keybinds.rows.filter(row => row.description.toLowerCase().includes(root.query) || root.keysText(row).toLowerCase().includes(root.query)).map(row => row.index)
    // The matches in reading order, which the arrows walk.
    readonly property list<int> order: {
        const order = [];
        for (const column of root.columns)
            for (const section of column)
                order.push(...section.rows.map(row => row.index).filter(index => root.matches.includes(index)));
        return order;
    }
    property int selected: -1
    readonly property var selectedRow: Keybinds.rows[root.selected] ?? null
    // Under the pointer, a key fades the binds without it and names those
    // with it, and nothing is selected meanwhile.
    readonly property var keyed: keyboard.hovered === "" ? [] : Keybinds.rows.filter(row => root.uses(row, keyboard.hovered))
    // The panel but the sections and the keyboard. The keyboard shrinks, down
    // to keyLeast a key, for the sections to fit; past that they scroll.
    readonly property real frame: Style.bar.padding * 2 + header.height + (Style.border.width + Style.bar.padding * 2) * 2
    readonly property real chrome: root.frame + keyboard.implicitHeight

    signal closeRequested

    function sectionOf(row): string {
        if (row.keys.every(key => key.startsWith("XF86")))
            return "HARDWARE KEYS";

        const description = row.description.toLowerCase();
        return root.sectionWords.find(section => section.words.some(word => description.includes(word)))?.title ?? "GENERAL";
    }

    function keysText(row): string {
        return row.modifiers.concat([Keybinds.keysLabel(row.keys)]).join(" ");
    }

    // The keys a row is pressed with: its modifiers' (the left ones), then
    // its own.
    function keysOf(row): list<string> {
        return row.modifiers.map(Keybinds.modifierKey).concat(row.keys);
    }

    // Whether a row has the key under the pointer among its keys.
    function uses(row, name: string): bool {
        return root.keysOf(row).some(key => keyboard.idOf(key) === name);
    }

    function step(by: int) {
        const count = root.order.length;
        if (count === 0)
            return;

        const position = root.order.indexOf(root.selected);
        root.selected = root.order[position < 0 ? (by > 0 ? 0 : count - 1) : (position + by + count) % count];
    }

    width: Math.max(sectionsView.contentWidth, keyboard.implicitWidth) + Style.bar.padding * 2
    height: root.chrome + sectionsView.height
    radius: Style.bar.radius
    color: Colors.base.surface
    border.color: Colors.base.edge
    border.width: Style.border.width
    Component.onCompleted: search.focusInput()
    // A search selects its first match, so its keys light up at once.
    onOrderChanged: root.selected = root.query === "" ? -1 : root.order[0] ?? -1
    Keys.onEscapePressed: root.closeRequested()
    Keys.onUpPressed: root.step(-1)
    Keys.onDownPressed: root.step(1)
    Keys.onTabPressed: root.step(1)
    Keys.onBacktabPressed: root.step(-1)

    GlassHighlight {}

    // Keeps clicks on the panel from closing it.
    MouseArea {
        anchors.fill: parent
    }

    Item {
        id: header

        height: Style.popup.itemHeight

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Style.bar.padding
        }

        Text {
            id: title

            text: "Keyboard shortcuts"
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.largeSize
            font.weight: Font.Bold

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
        }

        // The layout the keyboard is drawn in; a click is the next one.
        Row {
            spacing: Style.widgets.spacing

            anchors {
                left: title.right
                leftMargin: Style.settings.spacing
                verticalCenter: parent.verticalCenter
            }

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.keyboard
            }

            TextButton {
                anchors.verticalCenter: parent.verticalCenter
                text: KeyboardLayout.name
                enabled: KeyboardLayout.layouts.length > 1
                onClicked: KeyboardLayout.next()
            }
        }

        InputField {
            id: search

            width: Style.settings.fieldWidth
            placeholder: "Search shortcuts…"
            icon: Icons.search

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
        }
    }

    Rectangle {
        id: topRule

        height: Style.border.width
        color: Colors.base.border

        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            topMargin: Style.bar.padding
        }
    }

    Flickable {
        id: sectionsView

        width: sectionsView.contentWidth
        height: Math.max(Style.popup.itemHeight, Math.min(sectionsView.contentHeight, root.maximumHeight - root.chrome))
        contentWidth: columnsRow.implicitWidth
        contentHeight: Math.max(columnsRow.implicitHeight, Style.popup.itemHeight)
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        anchors {
            top: topRule.bottom
            topMargin: Style.bar.padding
            horizontalCenter: parent.horizontalCenter
        }

        Row {
            id: columnsRow

            spacing: Style.settings.padding

            Repeater {
                model: root.columns

                delegate: Column {
                    id: column

                    required property var modelData

                    width: Style.shortcuts.columnWidth
                    spacing: Style.settings.spacing

                    Repeater {
                        model: column.modelData

                        delegate: Column {
                            id: section

                            required property var modelData

                            width: column.width

                            Text {
                                bottomPadding: Style.widgets.spacing
                                text: section.modelData.title
                                color: Colors.text.muted
                                font.family: Style.text.font
                                font.pixelSize: Style.text.smallSize
                                font.weight: Font.Medium
                            }

                            Repeater {
                                model: section.modelData.rows

                                delegate: KeybindRow {
                                    id: entry

                                    width: section.width
                                    height: Style.popup.itemHeight
                                    inset: Style.widgets.padding
                                    color: root.selected === entry.modelData.index ? Colors.base.hover : "transparent"
                                    opacity: root.matches.includes(entry.modelData.index) && (keyboard.hovered === "" || root.uses(entry.modelData, keyboard.hovered)) ? 1 : Style.shortcuts.faded

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onEntered: root.selected = entry.modelData.index
                                    }

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: Style.animation.fast
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: Keybinds.rows.length === 0
            text: "Reading Hyprland's binds…"
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }
    }

    Rectangle {
        id: bottomRule

        height: Style.border.width
        color: Colors.base.border

        anchors {
            top: sectionsView.bottom
            left: parent.left
            right: parent.right
            topMargin: Style.bar.padding
        }
    }

    KeyboardView {
        id: keyboard

        unit: Math.max(Style.shortcuts.keyLeast, Math.min(Style.shortcuts.keySize, (root.maximumHeight - root.frame - sectionsView.contentHeight + Style.widgets.spacing) / keyboard.depth))
        lit: root.selectedRow === null ? [] : root.keysOf(root.selectedRow)
        bound: [].concat(...Keybinds.rows.map(root.keysOf))
        caption: root.selectedRow !== null ? root.selectedRow.description : keyboard.hovered !== "" ? root.keyed.map(row => row.description).join(" · ") : root.query !== "" && root.order.length === 0 ? "No shortcut matches" : ""
        onHoveredChanged: {
            if (keyboard.hovered !== "")
                root.selected = -1;
        }

        anchors {
            top: bottomRule.bottom
            topMargin: Style.bar.padding
            horizontalCenter: parent.horizontalCenter
        }
    }
}
