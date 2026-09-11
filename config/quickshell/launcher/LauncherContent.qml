// launcher/LauncherContent.qml
import QtQuick
import Quickshell
import Quickshell.Widgets
import "../style"

Rectangle {
    id: root

    signal launched()
    signal cancelled()

    function reset() {
        searchInput.text = ""
        resultsList.currentIndex = 0
        searchInput.forceActiveFocus()
    }

    function launch(idx) {
        const entry = filtered[idx]
        if (entry) entry.execute()
        launched()
    }

    height: 300
    width: 400
    radius: Style.bar.radius
    color: Qt.rgba(Colors.base.base.r, Colors.base.base.g, Colors.base.base.b, Colors.base.opacity)
    border.color: Colors.base.border
    border.width: Style.border.width

    // every visible .desktop entry — TODO: usage-based ranking later
    property var allApps: {
        const entries = [...DesktopEntries.applications.values]
        return entries.filter(e => e.name).sort((a, b) => a.name.localeCompare(b.name))
    }

    // recomputes automatically whenever searchInput.text changes
    property var filtered: {
        const q = searchInput.text.trim().toLowerCase()
        if (q === "") return allApps
        return allApps.filter(e => {
            const name = (e.name || "").toLowerCase()
            const comment = (e.comment || "").toLowerCase()
            return name.includes(q) || comment.includes(q)
        })
    }

    Column {
        anchors.fill: parent
        anchors.margins: Style.bar.padding
        spacing: Style.bar.spacing

        TextInput {
            id: searchInput
            width: parent.width
            height: 32
            color: Colors.text.base
            font.pixelSize: Style.text.size + 4
            font.family: Style.text.font
            focus: true
            clip: true

            Keys.onDownPressed: resultsList.incrementCurrentIndex()
            Keys.onUpPressed: resultsList.decrementCurrentIndex()
            Keys.onReturnPressed: root.launch(resultsList.currentIndex)
            Keys.onEscapePressed: root.cancelled()
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Colors.base.border
        }

        ListView {
            id: resultsList
            width: parent.width
            height: parent.height - searchInput.height - Style.bar.spacing * 2 - 1
            clip: true
            model: root.filtered
            currentIndex: 0
            highlightMoveDuration: 80

            // TODO(Phase 4): empty-state text when filtered.length === 0

            delegate: Rectangle {
                width: resultsList.width
                height: 40
                radius: Style.bar.radius / 2
                color: ListView.isCurrentItem ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: Style.widgets.spacing

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 24
                        source: Quickshell.iconPath(modelData.icon, true)
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        color: Colors.text.base
                        font.pixelSize: Style.text.size
                        font.family: Style.text.font
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.launch(index)
                }
            }
        }
    }
}
