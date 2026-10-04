pragma ComponentBehavior: Bound

import "../icons"
import "../services"
import "../style"
import QtQuick

// A tenkeyless keyboard in the layout in use (services/Keymap), ISO or ANSI as
// that layout has it. Keys are named as binds name them (a keysym, code:N):
// `lit` ones take the accent, `bound` ones a tint, and a bound key the board
// has no place for (a media key) gets one in a row above it, beside the
// `caption`, or without one a hint at what the tint means. `hovered` is the
// key under the pointer, as idOf() names it, and lit as well.
Item {
    id: root

    property list<string> lit: []
    property list<string> bound: []
    property string caption: ""
    property string hovered: ""
    // A key's size and spacing; `depth` is the keyboard's height in keys.
    property real unit: Style.shortcuts.keySize
    readonly property var board: root.layout(Keymap.iso)
    readonly property real span: Math.max(...root.board.map(key => key.x + key.width))
    readonly property var extras: {
        const onBoard = new Set(root.board.map(key => key.name));
        const extras = [];
        for (const key of root.bound) {
            const name = root.idOf(key);
            if (!onBoard.has(name) && !extras.some(extra => extra.name === name))
                extras.push({
                    name: name,
                    key: key,
                    x: 0,
                    y: 0,
                    width: 1,
                    height: 1
                });
        }
        extras.forEach((extra, index) => extra.x = root.span - extras.length + index);
        return extras;
    }
    // The board starts below the row of extras and the caption, as far below
    // it as the main block is below the function row.
    readonly property real boardTop: 1.5
    readonly property real depth: root.boardTop + Math.max(...root.board.map(key => key.y + key.height))
    readonly property list<string> litNames: root.lit.map(root.idOf)
    readonly property list<string> boundNames: root.bound.map(root.idOf)
    // Lucide's glyph for a key above the board, where it has one; the others
    // are named.
    readonly property var glyphs: ({
            XF86AudioRaiseVolume: Icons.volume2,
            XF86AudioLowerVolume: Icons.volume1,
            XF86AudioMute: Icons.volumeX,
            XF86AudioPlay: Icons.play,
            XF86AudioPause: Icons.pause,
            XF86AudioNext: Icons.skipForward,
            XF86AudioPrev: Icons.skipBack,
            XF86MonBrightnessUp: Icons.sun,
            XF86MonBrightnessDown: Icons.sunDim,
            XF86PowerOff: Icons.power
        })

    // The key a bind's key is on, or the bind's key where no key has it.
    function idOf(key) {
        return Keymap.keyOf(key) || key;
    }

    // The board in key widths: the function row, then the five rows of the
    // main block with the navigation keys and arrows a quarter key after it.
    // ISO adds the key left of Z and a two-row Enter, which a Tab a quarter
    // wider meets here, where a real one meets the Enter's wider top.
    function layout(iso) {
        const keys = [];
        const row = (y, entries) => {
            let x = 0;
            for (const entry of entries) {
                if (typeof entry === "number") {
                    x += entry;
                    continue;
                }
                // Not `const [name, width = 1] = entry`: in a loop, Qt 6.11
                // fills a missing element from the previous turn's.
                keys.push({
                    name: entry[0],
                    x: x,
                    y: y,
                    width: entry[1] ?? 1,
                    height: entry[2] ?? 1
                });
                x += entry[1] ?? 1;
            }
        };
        const run = (prefix, first, last) => Array.from({
                length: last - first + 1
            }, (_, index) => [prefix + String(first + index).padStart(2, "0")]);
        row(0, [["ESC"], 1, ...run("FK", 1, 4), 0.5, ...run("FK", 5, 8), 0.5, ...run("FK", 9, 12), 0.25, ["PRSC"], ["SCLK"], ["PAUS"]]);
        row(1.5, [["TLDE"], ...run("AE", 1, 12), ["BKSP", 2], 0.25, ["INS"], ["HOME"], ["PGUP"]]);
        row(2.5, [["TAB", iso ? 1.75 : 1.5], ...run("AD", 1, 12), iso ? ["RTRN", 1.25, 2] : ["BKSL", 1.5], 0.25, ["DELE"], ["END"], ["PGDN"]]);
        row(3.5, [["CAPS", 1.75], ...run("AC", 1, 11), iso ? ["BKSL"] : ["RTRN", 2.25]]);
        row(4.5, [...(iso ? [["LFSH", 1.25], ["LSGT"]] : [["LFSH", 2.25]]), ...run("AB", 1, 10), ["RTSH", 2.75], 1.25, ["UP"]]);
        row(5.5, [["LCTL", 1.25], ["LWIN", 1.25], ["LALT", 1.25], ["SPCE", 6.25], ["RALT", 1.25], ["RWIN", 1.25], ["COMP", 1.25], ["RCTL", 1.25], 0.25, ["LEFT"], ["DOWN"], ["RGHT"]]);
        return keys;
    }

    implicitWidth: root.span * root.unit - Style.widgets.spacing
    implicitHeight: root.depth * root.unit - Style.widgets.spacing

    Text {
        width: (root.span - root.extras.length) * root.unit - Style.bar.spacing
        height: root.unit - Style.widgets.spacing
        verticalAlignment: Text.AlignVCenter
        text: root.caption !== "" ? root.caption : "Shaded keys are part of a shortcut"
        color: root.caption !== "" ? Colors.text.base : Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.size
        elide: Text.ElideRight
    }

    Repeater {
        model: root.extras.concat(root.board)

        delegate: Rectangle {
            id: cap

            required property var modelData
            readonly property bool lit: root.litNames.includes(cap.modelData.name) || root.hovered === cap.modelData.name
            readonly property bool bound: root.boundNames.includes(cap.modelData.name)
            readonly property bool above: cap.modelData.key !== undefined
            readonly property string glyph: cap.above ? root.glyphs[cap.modelData.key] ?? "" : ""
            readonly property list<string> legend: cap.above ? [Keymap.label(cap.modelData.key)] : Keymap.legend(cap.modelData.name)

            x: cap.modelData.x * root.unit
            y: (cap.modelData.y + (cap.above ? 0 : root.boardTop)) * root.unit
            width: cap.modelData.width * root.unit - Style.widgets.spacing
            height: cap.modelData.height * root.unit - Style.widgets.spacing
            radius: Style.popup.rowRadius
            color: cap.lit ? Colors.accent.primary : cap.bound ? Colors.pill.selected : "transparent"
            border.width: Style.border.width
            border.color: area.containsMouse ? Colors.icon.active : Colors.base.border

            Column {
                anchors.centerIn: parent
                visible: cap.glyph === ""

                Repeater {
                    model: cap.legend

                    // Shift's character is muted, over the key's own.
                    delegate: Text {
                        id: line

                        required property string modelData
                        required property int index

                        width: cap.width - Style.widgets.spacing * 2
                        horizontalAlignment: Text.AlignHCenter
                        text: line.modelData
                        color: cap.lit ? Colors.text.inverted : cap.bound && line.index === cap.legend.length - 1 ? Colors.text.base : Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.smallSize
                        height: (cap.height - Style.widgets.spacing) / cap.legend.length
                        verticalAlignment: Text.AlignVCenter
                        fontSizeMode: Text.Fit
                        minimumPixelSize: Style.shortcuts.legendLeast
                    }
                }
            }

            Icon {
                anchors.centerIn: parent
                visible: cap.glyph !== ""
                text: cap.glyph
                color: cap.lit ? Colors.text.inverted : Colors.icon.active
            }

            MouseArea {
                id: area

                anchors.fill: parent
                hoverEnabled: true
                // Entering the next key may come before leaving this one.
                onContainsMouseChanged: {
                    if (area.containsMouse)
                        root.hovered = cap.modelData.name;
                    else if (root.hovered === cap.modelData.name)
                        root.hovered = "";
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Style.animation.fast
                }
            }
        }
    }
}
