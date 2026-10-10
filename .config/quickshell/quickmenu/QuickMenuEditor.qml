pragma ComponentBehavior: Bound

import "../icons"
import "../panels"
import "../services"
import "../style"
import QtQuick

// The pencil's panel beside the quick menu. With no slot picked, the menu's
// own options: how many slots, its size, whether a click closes it, and its
// motion.
// With one picked, what that slot holds: a category, and which of its items
// it shows, or a single shortcut, or nothing.
RingPanel {
    id: root

    required property QuickMenuItems items
    required property int slot
    readonly property string held: root.slot >= 0 ? QuickMenu.slots[root.slot] ?? "" : ""
    readonly property string heldCategory: root.held.startsWith("category:") ? root.held.slice("category:".length) : ""
    readonly property var shown: root.heldCategory !== "" ? QuickMenu.categories[root.heldCategory] ?? root.items.categories[root.heldCategory].shows ?? root.items.categories[root.heldCategory].items : []

    signal done
    signal settingsRequested

    // The way a slot points, as a compass has it.
    function direction(slot: int): string {
        const names = ["North", "North-east", "East", "South-east", "South", "South-west", "West", "North-west"];
        return names[Math.round(slot * 8 / QuickMenu.slots.length) % 8];
    }

    // Ticked items in the category's own order; one stays, and at most
    // maxItems show.
    function toggleShown(item: string) {
        const shown = Array.from(root.shown);
        const at = shown.indexOf(item);
        if (at >= 0 && shown.length > 1)
            shown.splice(at, 1);
        else if (at < 0 && shown.length < Style.quickMenu.maxItems)
            shown.push(item);
        QuickMenu.setItems(root.heldCategory, root.items.categories[root.heldCategory].items.filter(candidate => shown.includes(candidate)));
    }

    // Two to a row, each row on the curve.
    function pairs(entries: list<string>): var {
        const rows = [];
        for (let at = 0; at < entries.length; at += 2)
            rows.push(entries.slice(at, at + 2));
        return rows;
    }

    title: root.slot < 0 ? "Quick Menu" : root.direction(root.slot)
    contentHeight: root.slot < 0 ? options.implicitHeight : picker.implicitHeight
    onSlotChanged: scroller.contentY = 0
    trailing: [
        TextButton {
            visible: root.slot >= 0
            anchors.verticalCenter: parent.verticalCenter
            text: "Empty"
            onClicked: QuickMenu.setSlot(root.slot, "")
        },
        TextButton {
            anchors.verticalCenter: parent.verticalCenter
            text: "Done"
            color: Colors.text.base
            onClicked: root.done()
        }
    ]

    Flickable {
        id: scroller

        anchors.fill: parent
        clip: true
        containmentMask: root.bodyMask
        contentHeight: root.contentHeight
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: options

            visible: root.slot < 0
            spacing: Style.widgets.spacing

            Option {
                label: "SLOTS"
                choices: QuickMenu.counts.map(count => ({
                            label: String(count),
                            value: count
                        }))
                current: QuickMenu.slots.length
                onPicked: count => QuickMenu.setCount(count)
            }

            Option {
                label: "SIZE"
                choices: Style.quickMenu.sizes.map(size => ({
                            label: Math.round(size * 100) + "%",
                            value: size
                        }))
                current: QuickMenu.size
                onPicked: size => QuickMenu.setSize(size)
            }

            Option {
                label: "AFTER A CLICK"
                choices: [
                    {
                        label: "Stays open",
                        value: false
                    },
                    {
                        label: "Closes",
                        value: true
                    }
                ]
                current: QuickMenu.closeAfterClick
                onPicked: close => QuickMenu.setCloseAfterClick(close)
            }

            Option {
                label: "MOTION"
                choices: [
                    {
                        label: "Calm",
                        value: false
                    },
                    {
                        label: "Playful",
                        value: true
                    }
                ]
                current: QuickMenu.playful
                onPicked: playful => QuickMenu.setPlayful(playful)
            }

            Row {
                id: buttons

                x: root.place(buttons.y - scroller.contentY, buttons.height)
                height: Style.popup.itemHeight
                spacing: Style.bar.padding

                TextButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Keyboard settings…"
                    onClicked: root.settingsRequested()
                }

                TextButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Reset"
                    onClicked: QuickMenu.reset()
                }
            }
        }

        Column {
            id: picker

            visible: root.slot >= 0

            Heading {
                text: "A CATEGORY"
            }

            Repeater {
                model: root.pairs(Object.keys(root.items.categories).map(id => "category:" + id))

                delegate: Pair {}
            }

            Heading {
                visible: root.heldCategory !== ""
                text: `IT SHOWS · UP TO ${Style.quickMenu.maxItems}`
            }

            Repeater {
                model: root.heldCategory !== "" ? root.items.categories[root.heldCategory].items : []

                delegate: Item {
                    id: shownRow

                    required property string modelData
                    readonly property bool ticked: root.shown.includes(shownRow.modelData)
                    readonly property bool blocked: !shownRow.ticked && root.shown.length >= Style.quickMenu.maxItems

                    x: root.place(shownRow.y - scroller.contentY, shownRow.height)
                    width: root.rowWidth
                    height: Style.popup.itemHeight

                    Icon {
                        id: box

                        anchors.verticalCenter: parent.verticalCenter
                        text: shownRow.ticked ? Icons.squareCheck : Icons.square
                        color: shownRow.blocked ? Colors.icon.disabled : Colors.icon.active
                    }

                    Text {
                        anchors.left: box.right
                        anchors.leftMargin: Style.bar.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        text: shownRow.modelData === "devices" ? "Paired devices" : root.items.describe("item:" + shownRow.modelData).name
                        textFormat: Text.PlainText
                        color: shownRow.blocked ? Colors.icon.disabled : shownRow.ticked ? Colors.text.base : Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.size
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !shownRow.blocked
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleShown(shownRow.modelData)
                    }
                }
            }

            Heading {
                text: "OR ONE SHORTCUT"
            }

            Repeater {
                model: root.pairs(root.items.shortcuts.map(id => "item:" + id))

                delegate: Pair {}
            }
        }
    }

    component Option: PillGroup {
        id: option

        x: root.place(option.y - scroller.contentY, option.height)
        width: root.rowWidth
        compact: true
    }

    component Heading: Text {
        id: heading

        x: root.place(heading.y - scroller.contentY, heading.height)
        width: root.rowWidth
        topPadding: Style.widgets.spacing
        bottomPadding: Style.widgets.spacing
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
        font.weight: Font.Medium
    }

    // Two choices side by side.
    component Pair: Row {
        id: pair

        required property list<string> modelData

        x: root.place(pair.y - scroller.contentY, pair.height)

        Repeater {
            model: pair.modelData

            delegate: Choice {}
        }
    }

    // A category or a shortcut to put in the slot, checked where it is there.
    component Choice: Rectangle {
        id: choice

        required property string modelData
        readonly property var item: root.items.describe(choice.modelData)
        readonly property bool chosen: root.held === choice.modelData

        width: root.rowWidth / 2
        height: Style.popup.itemHeight
        radius: Style.popup.rowRadius
        color: choice.chosen ? Colors.pill.selected : area.containsMouse ? Colors.base.hover : "transparent"

        Icon {
            id: glyph

            anchors.left: parent.left
            anchors.leftMargin: Style.widgets.padding
            anchors.verticalCenter: parent.verticalCenter
            text: choice.item.icon
        }

        Text {
            anchors.left: glyph.right
            anchors.right: parent.right
            anchors.leftMargin: Style.bar.spacing
            anchors.verticalCenter: parent.verticalCenter
            text: choice.item.name
            textFormat: Text.PlainText
            color: choice.chosen ? Colors.text.base : Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            elide: Text.ElideRight
        }

        MouseArea {
            id: area

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: QuickMenu.setSlot(root.slot, choice.modelData)
        }
    }
}
