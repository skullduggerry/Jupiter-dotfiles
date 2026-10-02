pragma ComponentBehavior: Bound

import "../icons"
import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    readonly property var apps: DesktopEntries.applications.values.filter(entry => entry.name !== "").sort(LauncherHistory.compare)
    readonly property var shown: {
        const query = search.text.trim().toLowerCase();
        return query === "" ? root.apps : root.apps.filter(entry => entry.name.toLowerCase().includes(query) || entry.comment.toLowerCase().includes(query));
    }
    // What qalc is asked to work out: a search of numbers, operators and the
    // common functions by itself, anything at all after a leading "=" (units,
    // currencies: "= 5 km to mi"). A bare word would otherwise be a unit to it.
    readonly property string expression: {
        const query = search.text.trim();
        if (query.startsWith("="))
            return query.slice(1).trim();

        return /\d/.test(query) && /[-+*\/^%!]/.test(query) && /^(?:[\d\s.,+\-*\/^%!()]|sqrt|a?sin|a?cos|a?tan|log|ln|exp|abs|pi|e)+$/.test(query) ? query : "";
    }
    // qalc's answer, "" while there is none worth showing: one that only
    // repeats the sum ("3/0") says nothing.
    property string answer: ""

    signal launched
    signal cancelled

    function reset() {
        search.text = "";
        results.currentIndex = 0;
        search.forceActiveFocus();
    }

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

    // With qalc's minus sign as ASCII, so it pastes into anything.
    function copyAnswer() {
        Quickshell.execDetached(["wl-copy", "--", root.answer.replace(/\u2212/g, "-")]);
        root.launched();
    }

    function launch(index: int) {
        const entry = root.shown[index];
        if (entry === undefined)
            return;

        LauncherHistory.record(entry.execString);
        entry.execute();
        root.launched();
    }

    onExpressionChanged: root.calculate()
    width: Style.launcher.width
    height: Style.launcher.height
    radius: Style.bar.radius
    color: Colors.base.surface
    border.color: Colors.base.border
    border.width: Style.border.width

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

    Column {
        anchors.fill: parent
        anchors.margins: Style.bar.padding
        spacing: Style.bar.spacing

        TextInput {
            id: search

            width: parent.width
            height: Style.launcher.inputHeight
            color: Colors.text.base
            font.pixelSize: Style.text.largeSize
            font.family: Style.text.font
            focus: true
            clip: true
            Keys.onDownPressed: results.incrementCurrentIndex()
            Keys.onUpPressed: results.decrementCurrentIndex()
            Keys.onReturnPressed: {
                if (root.answer !== "")
                    root.copyAnswer();
                else
                    root.launch(results.currentIndex);
            }
            Keys.onEscapePressed: root.cancelled()
        }

        Rectangle {
            id: calculation

            visible: root.answer !== ""
            width: parent.width
            height: Style.launcher.rowHeight
            radius: Style.popup.rowRadius
            color: Colors.base.hover

            Icon {
                id: calculationIcon

                text: Icons.calculator

                anchors {
                    left: parent.left
                    leftMargin: Style.launcher.rowPadding
                    verticalCenter: parent.verticalCenter
                }
            }

            Text {
                text: root.answer
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.largeSize
                elide: Text.ElideRight

                anchors {
                    left: calculationIcon.right
                    right: copyHint.left
                    leftMargin: Style.launcher.rowPadding
                    rightMargin: Style.launcher.rowPadding
                    verticalCenter: parent.verticalCenter
                }
            }

            Text {
                id: copyHint

                text: "Enter to copy"
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize

                anchors {
                    right: parent.right
                    rightMargin: Style.launcher.rowPadding
                    verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.copyAnswer()
            }
        }

        Rectangle {
            width: parent.width
            height: Style.border.width
            color: Colors.base.border
        }

        Item {
            width: parent.width
            height: parent.height - search.height - Style.bar.spacing * 2 - Style.border.width - (calculation.visible ? calculation.height + Style.bar.spacing : 0)

            ListView {
                id: results

                anchors.fill: parent
                clip: true
                model: root.shown
                currentIndex: 0
                highlightMoveDuration: Style.animation.fast

                delegate: Rectangle {
                    id: result

                    required property DesktopEntry modelData
                    required property int index

                    width: results.width
                    height: Style.launcher.rowHeight
                    radius: Style.popup.rowRadius
                    color: result.ListView.isCurrentItem ? Colors.base.hover : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: Style.launcher.rowPadding
                        anchors.verticalCenter: parent.verticalCenter
                        text: result.modelData.name
                        color: Colors.text.base
                        font.pixelSize: Style.text.size
                        font.family: Style.text.font
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.launch(result.index)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: results.count === 0 && !calculation.visible
                text: "No matching applications"
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.size
            }
        }
    }
}
