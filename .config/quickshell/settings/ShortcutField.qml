pragma ComponentBehavior: Bound

import "../panels"
import "../services"
import "../style"
import QtQuick
import Quickshell.Hyprland

// A shortcut pressed rather than typed: click, then press the keys. While it
// records, every key comes here, the desktop's binds too (Tablet's submap);
// Escape, a click anywhere or leaving the window stops. The keys show as
// keycaps, as the Keybinds tab has them.
Rectangle {
    id: root

    // As Hyprland binds spell them, "CTRL + SHIFT + z"; "" for none yet.
    property string keys: ""
    property bool recording: false
    readonly property list<string> parts: root.keys === "" ? [] : root.keys.split("+").map(part => part.trim())

    signal recorded(string keys)

    function start() {
        root.recording = true;
        root.forceActiveFocus();
        Tablet.setRecording(true);
    }

    function stop() {
        if (!root.recording)
            return;

        root.recording = false;
        Tablet.setRecording(false);
    }

    // A modifier's bit in a key event: SUPER is Qt's Meta.
    function flag(modifier: string): int {
        return {
            SUPER: Qt.MetaModifier,
            CTRL: Qt.ControlModifier,
            ALT: Qt.AltModifier,
            SHIFT: Qt.ShiftModifier
        }[modifier];
    }

    implicitWidth: Style.settings.fieldWidth
    implicitHeight: Style.popup.itemHeight
    radius: Style.popup.rowRadius
    color: area.containsMouse ? Colors.pill.selected : Colors.base.hover
    border.width: Style.border.width
    border.color: root.recording ? Colors.icon.active : Colors.base.border
    onActiveFocusChanged: {
        if (!root.activeFocus)
            root.stop();
    }
    Component.onDestruction: root.stop()
    // Modifiers alone wait for the key they go with, which is named as the
    // layout binds go by names it unshifted: SHIFT + 1, not SHIFT + exclam.
    Keys.onPressed: event => {
        if (!root.recording)
            return;

        event.accepted = true;
        if ([Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_AltGr, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R].includes(event.key))
            return;

        if (event.key === Qt.Key_Escape && event.modifiers === Qt.NoModifier) {
            root.stop();
            return;
        }
        const key = Keymap.symOf(event.nativeScanCode);
        if (key === "")
            return;

        const held = Keybinds.modifiers.filter(modifier => (event.modifiers & root.flag(modifier.name)) !== 0).map(modifier => modifier.name);
        root.stop();
        root.recorded(held.concat([key]).join(" + "));
    }

    Row {
        visible: !root.recording && root.parts.length > 0
        spacing: Style.widgets.spacing

        anchors {
            left: parent.left
            leftMargin: Style.widgets.padding
            verticalCenter: parent.verticalCenter
        }

        Repeater {
            model: root.parts.map((part, index) => index === root.parts.length - 1 ? Keymap.label(part) : part)

            delegate: KeyCap {}
        }
    }

    Text {
        visible: root.recording || root.parts.length === 0
        text: root.recording ? "Press the keys…" : "Click to record"
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize

        anchors {
            left: parent.left
            leftMargin: Style.widgets.padding
            verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.start()
    }

    // A click anywhere in the window stops, this field included.
    MouseArea {
        parent: root.Window.contentItem
        visible: root.recording
        anchors.fill: parent
        z: 1
        onPressed: root.stop()
    }

    // Escape leaves the submap before it reaches the window.
    Connections {
        function onRawEvent(event: HyprlandEvent) {
            if (event.name === "submap" && event.data !== "tablet-record")
                root.recording = false;
        }

        target: Hyprland
    }
}
