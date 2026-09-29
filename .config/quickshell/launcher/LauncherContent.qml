pragma ComponentBehavior: Bound

import "../services"
import "../style"
import QtQuick
import Quickshell

Rectangle {
    id: root

    readonly property var apps: DesktopEntries.applications.values.filter(entry => entry.name !== "").sort(LauncherHistory.compare)
    readonly property var shown: {
        const query = search.text.trim().toLowerCase();
        return query === "" ? root.apps : root.apps.filter(entry => entry.name.toLowerCase().includes(query) || entry.comment.toLowerCase().includes(query));
    }

    signal launched
    signal cancelled

    function reset() {
        search.text = "";
        results.currentIndex = 0;
        search.forceActiveFocus();
    }

    function launch(index: int) {
        const entry = root.shown[index];
        if (entry === undefined)
            return;

        LauncherHistory.record(entry.execString);
        entry.execute();
        root.launched();
    }

    width: Style.launcher.width
    height: Style.launcher.height
    radius: Style.bar.radius
    color: Colors.base.surface
    border.color: Colors.base.border
    border.width: Style.border.width

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
            Keys.onReturnPressed: root.launch(results.currentIndex)
            Keys.onEscapePressed: root.cancelled()
        }

        Rectangle {
            width: parent.width
            height: Style.border.width
            color: Colors.base.border
        }

        Item {
            width: parent.width
            height: parent.height - search.height - Style.bar.spacing * 2 - Style.border.width

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
                visible: results.count === 0
                text: "No matching applications"
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.size
            }
        }
    }
}
