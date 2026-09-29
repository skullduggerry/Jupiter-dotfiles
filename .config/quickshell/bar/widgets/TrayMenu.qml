pragma ComponentBehavior: Bound

import "../../style"
import QtQuick
import Quickshell

WidgetPopup {
    id: root

    property var menuStack: []
    readonly property QsMenuHandle currentMenu: root.menuStack.length > 0 ? root.menuStack[root.menuStack.length - 1] : null
    readonly property bool nested: root.menuStack.length > 1

    function openAt(menu: QsMenuHandle, anchor: Item) {
        root.menuStack = [menu];
        root.anchorItem = anchor;
        root.visible = true;
    }

    function enterSubmenu(entry: QsMenuEntry) {
        root.menuStack = root.menuStack.concat([entry]);
    }

    function leaveSubmenu() {
        root.menuStack = root.menuStack.slice(0, -1);
    }

    namespaceSuffix: "tray-popup"
    popupWidth: Style.popup.width
    popupHeight: Math.max(Style.popup.minHeight, Math.min(Style.popup.maxHeight, backRow.height + entries.contentHeight + Style.bar.padding * 2))
    onVisibleChanged: {
        if (!root.visible)
            root.menuStack = [];
    }

    QsMenuOpener {
        id: opener

        menu: root.currentMenu
    }

    Item {
        anchors.fill: parent
        anchors.margins: Style.bar.padding

        Rectangle {
            id: backRow

            visible: root.nested
            height: backRow.visible ? Style.popup.itemHeight : 0
            radius: Style.popup.rowRadius
            color: backArea.containsMouse ? Colors.base.hover : "transparent"

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            Text {
                id: backIcon

                width: Style.popup.rowIconWidth
                text: "\u{F0141}"
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }

            Text {
                text: "Back"
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.size

                anchors {
                    left: backIcon.right
                    leftMargin: Style.widgets.spacing
                    verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: backArea

                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.leaveSubmenu()
            }
        }

        ListView {
            id: entries

            clip: true
            model: opener.children
            visible: entries.count > 0

            anchors {
                top: backRow.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }

            delegate: TrayMenuItem {
                id: entryRow

                width: entries.width
                onActivated: {
                    if (entryRow.modelData.hasChildren) {
                        root.enterSubmenu(entryRow.modelData);
                        return;
                    }
                    entryRow.modelData.triggered();
                    root.visible = false;
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: entries.count === 0
            text: "No menu entries"
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.size
        }
    }
}
