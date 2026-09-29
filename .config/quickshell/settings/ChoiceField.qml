pragma ComponentBehavior: Bound

import "../panels"
import "../style"
import QtQuick

// One choice out of a list too long for pills: the chosen label, opening onto
// the list below it, with a search field on top when `searchable`. Choices are
// {label, value}, with an optional muted {detail} and a {font} to draw it in.
Item {
    id: root

    property var choices: []
    property var current
    property bool searchable: false
    property int listWidth: root.width
    property bool expanded: false
    readonly property var currentChoice: root.choices.find(choice => choice.value === root.current) || null
    readonly property var shown: {
        const query = search.text.trim().toLowerCase();
        return query === "" ? root.choices : root.choices.filter(choice => choice.label.toLowerCase().includes(query));
    }

    signal picked(var value)

    function pick(value) {
        root.expanded = false;
        search.text = "";
        root.picked(value);
    }

    implicitWidth: Style.settings.fieldWidth
    implicitHeight: Style.popup.itemHeight
    onExpandedChanged: {
        if (root.expanded && root.searchable)
            search.focusInput();
        else if (root.expanded)
            root.forceActiveFocus();
    }
    // Closes the list before Escape reaches the window, which it would close.
    Keys.onEscapePressed: event => {
        event.accepted = root.expanded;
        root.expanded = false;
    }

    Rectangle {
        anchors.fill: parent
        radius: Style.popup.rowRadius
        color: fieldArea.containsMouse ? Colors.pill.selected : Colors.base.hover
        border.width: Style.border.width
        border.color: root.expanded ? Colors.icon.active : Colors.base.border

        Text {
            text: root.currentChoice !== null ? root.currentChoice.label : ""
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

        Text {
            id: chevron

            text: root.expanded ? "\u{F0143}" : "\u{F0140}"
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.iconSize

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
            onClicked: root.expanded = !root.expanded
        }
    }

    // Opaque: it opens over the controls below.
    Rectangle {
        visible: root.expanded
        y: root.height + Style.widgets.spacing
        width: root.listWidth
        height: Math.min(Style.settings.listHeight, (root.searchable ? search.height + Style.widgets.spacing : 0) + choiceList.contentHeight + Style.widgets.padding * 2)
        radius: Style.bar.radius
        color: Colors.base.base
        border.width: Style.border.width
        border.color: Colors.base.border

        InputField {
            id: search

            visible: root.searchable
            height: root.searchable ? search.implicitHeight : 0
            placeholder: "Search"
            icon: "\u{F0349}"
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
