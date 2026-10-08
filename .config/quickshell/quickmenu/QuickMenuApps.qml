pragma ComponentBehavior: Bound

import "../icons"
import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Io

// The launcher: the apps out beside their slot, most launched first
// (LauncherHistory), narrowed by what is typed, matched against their names
// and descriptions; by name only, as their own icons would be in a different
// style each. A sum goes to qalc, and its answer leads the list, to be
// copied. SUPER+R opens the menu with this list out and the keys in it.
RingList {
    id: root

    readonly property var apps: DesktopEntries.applications.values.filter(entry => entry.name !== "").sort(LauncherHistory.compare)
    readonly property var shown: {
        const query = root.query.trim().toLowerCase();
        return query === "" ? root.apps : root.apps.filter(entry => entry.name.toLowerCase().includes(query) || entry.comment.toLowerCase().includes(query));
    }
    // What qalc is asked to work out: a search of numbers, operators and the
    // common functions by itself, anything at all after a leading "=" (units,
    // currencies: "= 5 km to mi"). A bare word would otherwise be a unit to it.
    readonly property string expression: {
        const query = root.query.trim();
        if (query.startsWith("="))
            return query.slice(1).trim();

        return /\d/.test(query) && /[-+*\/^%!]/.test(query) && /^(?:[\d\s.,+\-*\/^%!()]|sqrt|a?sin|a?cos|a?tan|log|ln|exp|abs|pi|e)+$/.test(query) ? query : "";
    }
    // qalc's answer, "" while there is none worth showing: one that only
    // repeats the sum ("3/0") says nothing.
    property string answer: ""
    // The answer's row (null) first, then the apps.
    readonly property var entries: (root.answer !== "" ? [null] : []).concat(root.shown)

    // The command is set here, not bound: a binding on the expression would
    // only follow it after this runs, a keystroke late, and a bare `qalc`
    // never exits.
    function calculate() {
        if (root.expression === "") {
            root.answer = "";
        } else if (calculator.running) {
            calculator.stale = true;
        } else {
            calculator.command = ["qalc", "-t", root.expression];
            calculator.running = true;
        }
    }

    // An app counts toward its place in the order; the answer goes out with
    // qalc's minus sign as ASCII, so it pastes into anything.
    function pick(index: int): bool {
        if (index < 0 || index >= root.entries.length)
            return false;

        const entry = root.entries[index];
        if (entry === null) {
            Quickshell.execDetached(["wl-copy", "--", root.answer.replace(/\u2212/g, "-")]);
        } else {
            LauncherHistory.record(entry.execString);
            entry.execute();
        }
        root.picked();
        return true;
    }

    searchable: true
    model: root.entries
    onExpressionChanged: root.calculate()
    leading: [
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.search
            color: Colors.text.muted
        },
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.rowWidth - Style.text.iconSize - Style.widgets.spacing * 2 - Style.border.width)
            text: root.query
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.size
            elide: Text.ElideLeft
        },
        // The keys come here while `typing`.
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.typing
            width: Style.border.width
            height: Style.text.size
            color: Colors.text.base

            SequentialAnimation on opacity {
                loops: Animation.Infinite

                PauseAnimation {
                    duration: Style.quickMenu.caretBlink
                }

                PropertyAction {
                    value: 0
                }

                PauseAnimation {
                    duration: Style.quickMenu.caretBlink
                }

                PropertyAction {
                    value: 1
                }
            }
        },
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.query === ""
            text: "Search apps"
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }
    ]

    delegate: Item {
        id: row

        // null for the answer's row.
        required property DesktopEntry modelData
        required property int index

        width: root.view.width
        height: Style.popup.itemHeight

        // Clicks only on the row itself, as the clipboard's.
        Rectangle {
            x: root.place(row.y - root.view.contentY, row.height)
            width: root.rowWidth
            height: row.height
            radius: Style.popup.rowRadius
            color: row.index === root.current ? Colors.base.hover : "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: root.pick(row.index)
            }

            Text {
                id: name

                width: Math.min(implicitWidth, parent.width - Style.widgets.padding * 2)
                text: row.modelData !== null ? row.modelData.name : "= " + root.answer
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
                elide: Text.ElideRight

                anchors {
                    left: parent.left
                    leftMargin: Style.widgets.padding
                    verticalCenter: parent.verticalCenter
                }
            }

            Text {
                text: row.modelData?.comment ?? ""
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight

                anchors {
                    left: name.right
                    right: parent.right
                    leftMargin: Style.bar.spacing
                    rightMargin: Style.widgets.padding
                    verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Process {
        id: calculator

        // The search changed during a sum: work out the latest once more.
        property bool stale: false

        onRunningChanged: {
            if (!calculator.running && calculator.stale) {
                calculator.stale = false;
                root.calculate();
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const answer = text.trim();
                const flat = value => value.replace(/\u2212/g, "-").replace(/\s/g, "");
                root.answer = root.expression === "" || flat(answer) === flat(root.expression) ? "" : answer;
            }
        }
    }

    Text {
        id: empty

        visible: root.count === 0
        x: root.place(empty.y, empty.height)
        y: (root.view.height - empty.height) / 2
        width: root.rowWidth
        horizontalAlignment: Text.AlignHCenter
        text: "No matching apps"
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.size
    }
}
