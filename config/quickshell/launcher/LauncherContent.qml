// launcher/LauncherContent.qml
import QtQuick
import Quickshell
import Quickshell.Widgets
import "../services"
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

    function launch(idx: int) {
        const entry = root.filtered[idx]
        // Nothing matched the query — keep the launcher open rather than
        // dismissing it as though something had been started.
        if (!entry) return
        LauncherHistory.record(entry.execString)
        entry.execute()
        root.launched()
    }

    height: Style.launcher.height
    width: Style.launcher.width
    radius: Style.bar.radius
    color: Colors.base.surface
    border.color: Colors.base.border
    border.width: Style.border.width

    // Every visible .desktop entry, most-launched first and alphabetical
    // within a tie — so a fresh install still reads as an alphabetical list
    // and drifts towards what actually gets used.
    property var allApps: {
        const entries = [...DesktopEntries.applications.values]
        return entries.filter(e => e.name).sort(LauncherHistory.compare)
    }

    // recomputes automatically whenever searchInput.text changes
    property var filtered: {
        const q = searchInput.text.trim().toLowerCase()
        if (q === "") return root.allApps
        return root.allApps.filter(e => {
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
            height: Style.launcher.inputHeight
            color: Colors.text.base
            font.pixelSize: Style.text.largeSize
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
            height: Style.border.width
            color: Colors.base.border
        }

        Item {
            width: parent.width
            height: parent.height - searchInput.height - Style.bar.spacing * 2 - Style.border.width

            ListView {
                id: resultsList
                anchors.fill: parent
                clip: true
                model: root.filtered
                currentIndex: 0
                highlightMoveDuration: Style.animation.fast

                delegate: Rectangle {
                    id: result
                    required property DesktopEntry modelData
                    required property int index

                    width: resultsList.width
                    height: Style.launcher.rowHeight
                    radius: Style.popup.rowRadius
                    color: result.ListView.isCurrentItem ? Colors.base.hover : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.margins: Style.launcher.rowPadding
                        spacing: Style.widgets.spacing

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Style.launcher.iconSize
                            height: Style.launcher.iconSize

                            IconImage {
                                id: appIcon
                                anchors.fill: parent
                                // Explicit size from the start; otherwise the
                                // Image loads at sourceSize 0x0 and Qt
                                // rasterizes scalable icons (hicolor ships
                                // plenty of SVGs) at their natural size.
                                implicitSize: Style.launcher.iconSize
                                // `true` makes iconPath return "" rather than an
                                // unresolvable url, so status stays Null and the
                                // glyph below takes over.
                                source: Quickshell.iconPath(result.modelData.icon, true)
                                visible: status === Image.Ready
                            }

                            // Entries whose icon the theme can't resolve (or a
                            // system with no icon theme configured at all) get a
                            // generic glyph from the Nerd Font the rest of the
                            // shell already requires, instead of an empty gap.
                            Text {
                                anchors.centerIn: parent
                                visible: !appIcon.visible
                                text: "󰘔"
                                color: Colors.text.muted
                                font.family: Style.text.font
                                font.pixelSize: Style.launcher.iconSize
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: result.modelData.name
                            color: Colors.text.base
                            font.pixelSize: Style.text.size
                            font.family: Style.text.font
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.launch(result.index)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: resultsList.count === 0
                text: "No matching applications"
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.size
            }
        }
    }
}
