pragma ComponentBehavior: Bound

import "../icons"
import "../panels"
import "../style"
import QtQuick
import Quickshell

// One choice out of a list too long for pills: the chosen label, opening onto
// the list below it, with a search field on top when `searchable`. Choices are
// {label, value}, with an optional muted {detail} and a {font} to draw it in.
// The list is a popup of its own, as a menu is: drawn over the whole window
// and past its edges, on the shell's glass (Hyprland's blur.popups), above the
// field where there is no room below, and closed by a click anywhere else.
Item {
    id: root

    property var choices: []
    property var current
    property bool searchable: false
    property int listWidth: root.width
    // The compositor closes the popup on a click outside it.
    property alias expanded: list.visible
    readonly property var currentChoice: root.choices.find(choice => choice.value === root.current) || null
    readonly property var shown: {
        const query = search.text.trim().toLowerCase();
        return query === "" ? root.choices : root.choices.filter(choice => choice.label.toLowerCase().includes(query));
    }

    signal picked(var value)

    function pick(value) {
        root.expanded = false;
        root.picked(value);
    }

    implicitWidth: Style.settings.fieldWidth
    implicitHeight: Style.popup.itemHeight

    Rectangle {
        anchors.fill: parent
        radius: Style.popup.rowRadius
        color: fieldArea.containsMouse ? Colors.pill.selected : Colors.base.hover
        border.width: Style.border.width
        border.color: root.expanded ? Colors.icon.active : Colors.base.border

        Text {
            text: root.currentChoice !== null ? root.currentChoice.label : ""
            textFormat: Text.PlainText
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.size
            elide: Text.ElideRight

            anchors {
                left: parent.left
                right: chevron.left
                leftMargin: Style.widgets.padding
                rightMargin: Style.widgets.spacing
                verticalCenter: parent.verticalCenter
            }
        }

        Icon {
            id: chevron

            text: root.expanded ? Icons.chevronUp : Icons.chevronDown
            color: Colors.text.muted

            anchors {
                right: parent.right
                rightMargin: Style.widgets.padding
                verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: fieldArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = true
        }
    }

    // Hyprland closes the list at a click in another window but passes one in
    // this window on, so this takes it, as a menu does: the field included,
    // and the wheel, so the page stays put under the list.
    MouseArea {
        parent: root.Window.contentItem
        visible: root.expanded
        anchors.fill: parent
        z: 1
        onPressed: root.expanded = false
        onWheel: {}
    }

    PopupWindow {
        id: list

        // The gap below the field, or above it when the list opens upwards.
        anchor.item: root
        anchor.rect.y: -Style.widgets.spacing
        anchor.rect.width: root.width
        anchor.rect.height: root.height + Style.widgets.spacing * 2
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.adjustment: PopupAdjustment.FlipY | PopupAdjustment.SlideX
        grabFocus: true
        implicitWidth: root.listWidth
        implicitHeight: Math.min(Style.settings.listHeight, (root.searchable ? search.height + Style.widgets.spacing : 0) + choiceList.contentHeight + Style.widgets.padding * 2)
        color: "transparent"
        onVisibleChanged: {
            search.text = "";
            if (list.visible && root.searchable)
                search.focusInput();
            else if (list.visible)
                frame.forceActiveFocus();
        }

        Rectangle {
            id: frame

            anchors.fill: parent
            radius: Style.bar.radius
            color: Colors.base.surface
            border.width: Style.border.width
            border.color: Colors.base.edge
            Keys.onEscapePressed: root.expanded = false

            // The list's popup is the glass, so Hyprland's lens frames it.
            GlassHighlight {
                lensed: true
            }

            InputField {
                id: search

                visible: root.searchable
                height: root.searchable ? search.implicitHeight : 0
                placeholder: "Search"
                icon: Icons.search
                Keys.onEscapePressed: root.expanded = false
                onAccepted: {
                    if (root.shown.length > 0)
                        root.pick(root.shown[0].value);
                }

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: Style.widgets.padding
                }
            }

            ListView {
                id: choiceList

                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.shown

                anchors {
                    top: search.bottom
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                    topMargin: root.searchable ? Style.widgets.spacing : 0
                    leftMargin: Style.widgets.padding
                    rightMargin: Style.widgets.padding
                    bottomMargin: Style.widgets.padding
                }

                delegate: Rectangle {
                    id: choiceRow

                    required property var modelData

                    width: choiceList.width
                    height: Style.popup.itemHeight
                    radius: Style.popup.rowRadius
                    color: choiceRow.modelData.value === root.current ? Colors.pill.selected : choiceArea.containsMouse ? Colors.base.hover : "transparent"

                    Text {
                        text: choiceRow.modelData.label
                        textFormat: Text.PlainText
                        color: Colors.text.base
                        font.family: choiceRow.modelData.font || Style.text.font
                        font.pixelSize: Style.text.size
                        elide: Text.ElideRight

                        anchors {
                            left: parent.left
                            right: detail.left
                            leftMargin: Style.widgets.padding
                            rightMargin: Style.widgets.spacing
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        id: detail

                        text: choiceRow.modelData.detail || ""
                        textFormat: Text.PlainText
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
                        id: choiceArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.pick(choiceRow.modelData.value)
                    }
                }
            }
        }
    }
}
