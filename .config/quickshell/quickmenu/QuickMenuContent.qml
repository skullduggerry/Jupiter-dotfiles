pragma ComponentBehavior: Bound

import "../services"
import "../style"
import QtQuick
import QtQuick.Shapes

// The quick menu over its window: a hub (Settings and the pencil, or what is
// selected), a ring of slots and, past a category's slot, an arc of its
// items, the tree out along the radius; past a list's slot (the apps', the
// clipboard's), a RingList of its entries instead. Drawn in one of two looks
// on the same places: Halo, one disc with the arc a band hugging it, or
// Orbit, a round button per slot and item on a track (QuickMenu.look). The
// pointer selects by its direction from the centre, up to `reach` past the
// arc, and on a panel by where it is; letters, the arrows, 1 to 8 and Enter
// do the same from the keyboard, and once the apps' list is entered, letters
// type into it.
FocusScope {
    id: root

    required property QuickMenuItems items
    // Where the pointer was as the key went down, in this window.
    required property point origin
    // The key is still down: letting go uses what is selected.
    property bool holding: false
    // Opened as the launcher (SUPER+R): the apps' list out with the keys in
    // it, the ring and the list centred together on `origin`.
    property bool launcher: false
    // Open after the key: tapped, a category opened, something to confirm.
    property bool pinned: false
    // An item used by its letter while the key was down: letting go closes.
    property bool acted: false
    property bool editing: false
    property int editSlot: -1
    property int dragFrom: -1
    property bool dragged: false
    property point pointer: root.origin
    // A menu shifted to fit is not under the pointer: it selects nothing
    // until the pointer has moved.
    property bool armed: true
    // Where the launcher's pointer was first seen, which it is not opened at.
    property point rest: Qt.point(-1, -1)
    property real openedAt: 0
    // "ring" (a slot), "arc" (an item of the category out), "panel" (a panel
    // beside it: the list's row, -1 off its rows), "settings" or "edit" (the
    // centre's halves), "done" (the centre while editing), "".
    property string selectedArea: ""
    property int selectedIndex: -1
    // The slot whose category or list is out, and whether the pointer has
    // been among its items, after which another slot takes over only after
    // switchDelay; a list's panel waits that long from the start, as the way
    // to it can cross other slots.
    property int arcSlot: -1
    property bool arcEntered: false
    property int pendingSlot: -1
    // An item that asks again first, until confirmTimeout.
    property string confirming: ""
    property real wheelTravel: 0
    // A list's slot the wheel went into the list from: its row stays picked
    // while the pointer stays on the slot.
    property int wheelSlot: -1
    // The letters, shown once the pointer has rested or a key is pressed:
    // a flick that already knows where it goes never needs them.
    property bool keysShown: false
    readonly property bool playful: QuickMenu.playful
    // Auto: round buttons over blur, where the wallpaper shows between them,
    // and the one disc over a solid surface.
    readonly property bool orbit: QuickMenu.look === "orbit" || (QuickMenu.look === "auto" && Theme.blur)
    readonly property list<string> slots: QuickMenu.slots
    readonly property int count: root.slots.length
    readonly property real step: 360 / Math.max(1, root.count)
    readonly property var arcItems: root.arcSlot >= 0 && !root.editing ? root.items.itemsOf(root.slots[root.arcSlot] ?? "") : []
    readonly property bool listOut: root.arcSlot >= 0 && !root.editing && root.items.kindOf(root.slots[root.arcSlot] ?? "") === "list"
    readonly property RingList list: listPanel.item as RingList
    readonly property bool typing: root.list !== null && root.list.searchable && (root.arcEntered || root.selectedArea === "panel")
    readonly property int appsSlot: root.slots.indexOf("item:apps")
    readonly property real span: root.arcItems.length <= Style.quickMenu.fewItems ? Style.quickMenu.fewItemSpan : Style.quickMenu.itemSpan
    readonly property real arcStart: root.arcSlot * root.step - root.span * root.arcItems.length / 2
    // An arc's items read left to right and down, as they are listed:
    // clockwise on the ring's right and upper side, the other way round on
    // its left and lower side (arcAngle()).
    readonly property bool arcReversed: root.arcSlot * root.step > 90 && root.arcSlot * root.step <= 270
    readonly property var ringKeys: root.items.keysFor(root.slots)
    readonly property var arcKeys: root.items.keysFor(root.arcItems)
    readonly property string selectedEntry: {
        switch (root.selectedArea) {
        case "ring":
            return root.slots[root.selectedIndex] ?? "";
        case "arc":
            return root.arcItems[root.selectedIndex] ?? "";
        case "panel":
            return root.listOut ? root.slots[root.arcSlot] : "";
        }
        return "";
    }
    readonly property var selectedItem: root.items.describe(root.selectedEntry)
    // The slot the selection is at or out from: Orbit's line from the hub
    // runs to it.
    readonly property int selectedSlot: {
        switch (root.selectedArea) {
        case "ring":
            return root.selectedIndex;
        case "arc":
        case "panel":
            return root.arcSlot;
        }
        return -1;
    }
    // Where a slot or an item sits: the middle of its band.
    readonly property real slotRadius: (Style.quickMenu.centerRadius + Style.quickMenu.ringOuter) / 2
    readonly property real itemRadius: (Style.quickMenu.arcInner + Style.quickMenu.arcOuter) / 2
    // The slot whose category is out, while the pointer is among its items:
    // the rest fade back.
    readonly property bool focusedOnArc: root.arcSlot >= 0 && root.arcEntered
    readonly property real extent: Style.quickMenu.arcOuter
    // At the size picked, smaller on a screen too small for it.
    readonly property real zoom: Math.min(QuickMenu.size, (Math.min(root.width, root.height) / 2 - Style.quickMenu.margin) / root.extent)
    // How far across from the centre a panel beside the ring reaches.
    readonly property real panelReach: (Style.quickMenu.arcInner + Style.quickMenu.panelWidth) * root.zoom + Style.quickMenu.margin
    readonly property point center: {
        const room = root.extent * root.zoom + Style.quickMenu.margin;
        const x = root.origin.x - (root.launcher && root.appsSlot >= 0 ? root.sideOf(root.appsSlot) * (Style.quickMenu.arcInner + Style.quickMenu.panelWidth - root.extent) / 2 * root.zoom : 0);
        // A list's panel goes out on its slot's side, which needs room for it.
        const sides = root.slots.map((entry, slot) => root.items.kindOf(entry) === "list" ? root.sideOf(slot) : 0);
        const left = sides.includes(-1) ? Math.max(room, root.panelReach) : room;
        const right = sides.includes(1) ? Math.max(room, root.panelReach) : room;
        return Qt.point(root.width < left + right ? root.width / 2 : Math.max(left, Math.min(root.width - right, x)), root.height < room * 2 ? root.height / 2 : Math.max(room, Math.min(root.height - room, root.origin.y)));
    }
    // The pencil's panel: right of the menu where it fits, else left.
    readonly property int editorSide: root.center.x + root.panelReach <= root.width ? 1 : -1

    signal closeRequested

    // The side a slot's panel goes out on: its own, the right for the top and
    // the bottom.
    function sideOf(slot: int): int {
        return slot * root.step > 180 ? -1 : 1;
    }

    // Whether Halo's label goes above its glyph, away from the hub: on the
    // ring's upper half; on the lower, and level with the hub, under it.
    function labelAbove(angle: real): bool {
        return Math.cos(angle * Math.PI / 180) > 0.01;
    }

    // Where the middle of a label is, for a slot or an item whose middle is
    // `at`: RingItem puts it half its badge and spacing above or below.
    function labelPoint(at: point, angle: real): point {
        return Qt.point(at.x, at.y + (root.labelAbove(angle) ? -1 : 1) * (Style.toggles.badgeSize + Style.widgets.spacing) / 2);
    }

    // How wide a label can be, its middle at `at`, inside its piece of the
    // ring: the band from `inner` to `outer` between the angles `from` and
    // `to`; the label stays centred on its glyph.
    function room(at: point, inner: real, outer: real, from: real, to: real): real {
        const y = at.y;
        let half = Infinity;
        for (const side of [-1, 1]) {
            let reach = Math.sqrt(Math.max(0, outer * outer - y * y)) - side * at.x;
            if (side * at.x < 0 && Math.abs(y) < inner)
                reach = Math.min(reach, Math.abs(at.x) - Math.sqrt(inner * inner - y * y));
            for (const angle of [from, to]) {
                const turn = angle * Math.PI / 180;
                const along = -y / Math.cos(turn);
                const ahead = side * (along * Math.sin(turn) - at.x);
                if (along > 0 && ahead > 0)
                    reach = Math.min(reach, ahead);
            }
            half = Math.min(half, reach);
        }
        return 2 * (half - Style.quickMenu.gap / 2);
    }

    // Where an arc's item starts round the ring, and which item is at a
    // place along the arc: the same count either way round.
    function arcAngle(index: int): real {
        return root.arcStart + root.arcIndex(index) * root.span;
    }

    function arcIndex(place: int): int {
        return root.arcReversed ? root.arcItems.length - 1 - place : place;
    }

    function polar(radius: real, angle: real): point {
        const turn = (angle - 90) * Math.PI / 180;
        return Qt.point(radius * Math.cos(turn), radius * Math.sin(turn));
    }

    // What lies at a point of the window: {area, index}.
    function hit(x: real, y: real): var {
        const dx = (x - root.center.x) / root.zoom;
        const dy = (y - root.center.y) / root.zoom;
        // A panel out beside the menu first: it reaches past everything else.
        const panel = (root.list ?? editorPanel.item) as RingPanel;
        if (panel?.covers(dx, dy))
            return {
                area: "panel",
                index: root.list?.rowAt(dx, dy) ?? -1
            };

        const distance = Math.hypot(dx, dy);
        const angle = (Math.atan2(dx, -dy) * 180 / Math.PI + 360) % 360;
        if (distance > root.extent + Style.quickMenu.reach)
            return {
                area: "",
                index: -1
            };

        if (distance < Style.quickMenu.centerRadius) {
            if (root.editing)
                return {
                    area: "done",
                    index: -1
                };

            return {
                area: distance < Style.quickMenu.tapSlop ? "" : dx < 0 ? "settings" : "edit",
                index: -1
            };
        }
        const slot = Math.round(angle / root.step) % root.count;
        if (root.editing)
            return {
                area: distance <= Style.quickMenu.arcInner ? "ring" : "",
                index: slot
            };

        if (root.arcItems.length > 0 && distance > Style.quickMenu.ringOuter + Style.quickMenu.gap) {
            // A little past either end still counts, as the pointer swings out.
            const slack = root.span / 4;
            const along = (angle - root.arcStart + slack + 360) % 360 - slack;
            if (along <= root.span * root.arcItems.length + slack)
                return {
                    area: "arc",
                    index: root.arcIndex(Math.max(0, Math.min(root.arcItems.length - 1, Math.floor(along / root.span))))
                };
        }
        return {
            area: "ring",
            index: slot
        };
    }

    function select(area: string, index: int, fromKeys: bool) {
        root.selectedArea = area;
        root.selectedIndex = index;
        if (root.editing || area !== "ring") {
            if (area === "arc" || area === "panel")
                root.arcEntered = true;
            switcher.stop();
            return;
        }
        const target = ["category", "list"].includes(root.items.kindOf(root.slots[index] ?? "")) ? index : -1;
        if (target === root.arcSlot) {
            switcher.stop();
            return;
        }
        if (!fromKeys && root.arcSlot >= 0 && (root.arcEntered || root.listOut)) {
            if (!switcher.running || root.pendingSlot !== target) {
                root.pendingSlot = target;
                switcher.restart();
            }
            return;
        }
        switcher.stop();
        root.arcSlot = target;
        root.arcEntered = false;
    }

    function move(x: real, y: real) {
        root.pointer = Qt.point(x, y);
        if (!root.keysShown)
            keyDelay.restart();
        if (!root.armed) {
            // The launcher's pointer may be anywhere, even resting over the
            // menu: it takes over once it moves there, not when it is
            // nudged on the way to typing.
            if (root.launcher && root.rest.x < 0)
                root.rest = Qt.point(x, y);
            const from = root.launcher ? root.rest : root.origin;
            if (Math.hypot(x - from.x, y - from.y) < Style.quickMenu.armSlop || (root.launcher && Math.hypot(x - root.center.x, y - root.center.y) > root.extent * root.zoom && root.hit(x, y).area !== "panel"))
                return;
            root.armed = true;
        }
        const target = root.hit(x, y);
        if (root.wheelSlot >= 0 && target.area === "ring" && target.index === root.wheelSlot)
            return;
        root.wheelSlot = -1;
        if (target.area !== root.selectedArea || target.index !== root.selectedIndex)
            root.select(target.area, target.index, false);
    }

    function click(x: real, y: real) {
        const target = root.hit(x, y);
        if (target.area === "") {
            if (!root.back())
                root.closeRequested();
            return;
        }
        root.select(target.area, target.index, false);
        root.use("click");
    }

    // How: "click", "key", "release" (the key let go), "held" (a letter
    // with the key still down).
    function use(how: string) {
        switch (root.selectedArea) {
        case "settings":
            root.closeRequested();
            SettingsState.show("");
            return;
        case "edit":
            root.startEditing();
            return;
        case "done":
            root.editing = false;
            root.editSlot = -1;
            return;
        case "panel":
            if (!root.editing && !root.list?.pick(root.selectedIndex) && how === "release")
                root.closeRequested();
            return;
        }
        if (root.editing) {
            if (root.selectedArea === "ring")
                root.editSlot = root.selectedIndex;
            return;
        }
        const entry = root.selectedEntry;
        const item = root.selectedItem;
        if (item.kind === "empty" || item.disabled) {
            if (how === "release")
                root.closeRequested();
            return;
        }
        if (item.kind === "category" || item.kind === "list") {
            root.openTree(root.selectedIndex, how);
            return;
        }
        // A level changes by scrolling or the arrows, with the menu kept.
        if (item.kind === "level") {
            root.pinned = true;
            return;
        }
        if (item.confirm && root.confirming !== entry) {
            root.confirming = entry;
            root.pinned = true;
            confirmation.restart();
            return;
        }
        root.confirming = "";
        root.items.use(entry);
        if (how === "held")
            root.acted = true;
        else if (item.closes || how === "release" || QuickMenu.closeAfterClick)
            root.closeRequested();
    }

    // A category's arc or a list's panel, from its slot; from the keys, on
    // its first item.
    function openTree(slot: int, how: string) {
        root.pinned = true;
        switcher.stop();
        root.arcSlot = slot;
        root.arcEntered = true;
        if (how === "key" || how === "held")
            root.select(root.listOut ? "panel" : "arc", 0, true);
    }

    // The key let go: a tap keeps the menu, a hold uses what the pointer got to.
    function release() {
        if (!root.holding)
            return;

        root.holding = false;
        if (root.acted) {
            root.closeRequested();
            return;
        }
        if (root.pinned)
            return;

        const moved = Math.hypot(root.pointer.x - root.origin.x, root.pointer.y - root.origin.y) >= Style.quickMenu.tapSlop;
        if (!moved && Date.now() - root.openedAt < Style.quickMenu.tapTime) {
            root.pinned = true;
            return;
        }
        if (["ring", "arc", "panel"].includes(root.selectedArea))
            root.use("release");
        else
            root.closeRequested();
    }

    // Escape and Backspace: what was asked, what was typed, the slot picked,
    // the arc or the list, or the editing; false when there is nothing left
    // to go back from.
    function back(): bool {
        if (root.confirming !== "") {
            root.confirming = "";
            return true;
        }
        if (root.list !== null && root.list.query !== "") {
            root.list.query = "";
            return true;
        }
        if (root.editing) {
            if (root.editSlot >= 0)
                root.editSlot = -1;
            else
                root.editing = false;
            return true;
        }
        if (root.arcSlot >= 0 && (root.arcEntered || root.selectedArea === "arc" || root.selectedArea === "panel")) {
            const slot = root.arcSlot;
            root.arcEntered = false;
            root.select("ring", slot, true);
            return true;
        }
        return false;
    }

    function startEditing() {
        root.editing = true;
        root.editSlot = -1;
        root.pinned = true;
        root.arcSlot = -1;
        root.select("", -1, true);
    }

    // The arrows and Tab: round the ring, or along the arc.
    function stepSelection(direction: int) {
        if (root.editing) {
            root.editSlot = (root.editSlot + direction + root.count) % root.count;
            return;
        }
        if (root.selectedArea === "arc") {
            root.select("arc", (root.selectedIndex + direction + root.arcItems.length) % root.arcItems.length, true);
            return;
        }
        let slot = root.selectedArea === "ring" ? root.selectedIndex : root.selectedArea === "panel" && root.listOut ? root.arcSlot : direction > 0 ? -1 : 0;
        for (let tried = 0; tried < root.count; tried++) {
            slot = (slot + direction + root.count) % root.count;
            if (root.slots[slot] !== "")
                break;
        }
        root.select("ring", slot, true);
    }

    // Up and down the list out beside the menu.
    function stepRow(by: int) {
        if (root.list === null || root.list.count === 0)
            return;

        const row = Math.max(0, Math.min(root.list.count - 1, root.selectedIndex + by));
        root.select("panel", row, true);
        root.list.show(row);
    }

    // A key typed into the apps' list: a character, or Backspace while
    // there is something to take back; false for any other key. What was
    // typed starts the list over, on its first row.
    function type(event: KeyEvent): bool {
        const code = event.text.charCodeAt(0);
        if (event.key === Qt.Key_Backspace && root.list.query !== "")
            root.list.query = root.list.query.slice(0, -1);
        else if (event.text.length === 1 && code >= 32 && code !== 127 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) && (code !== 32 || root.list.query !== ""))
            root.list.query += event.text;
        else
            return false;
        root.select("panel", 0, true);
        root.list.show(0);
        return true;
    }

    // A letter: among the open category's items first, then the slots.
    function useLetter(letter: string, how: string) {
        if (root.arcItems.length > 0 && (root.arcEntered || root.selectedArea === "arc")) {
            const item = root.arcKeys.indexOf(letter);
            if (item >= 0) {
                root.select("arc", item, true);
                root.use(how);
                return;
            }
        }
        const slot = root.ringKeys.indexOf(letter);
        if (slot >= 0) {
            root.select("ring", slot, true);
            root.use(how);
        }
    }

    // What scrolling changes (QuickMenuItems' adjustable); false for anything
    // else, where Up opens a category.
    function adjust(steps: int): bool {
        if (root.selectedItem.adjustable && !root.selectedItem.disabled) {
            root.items.adjust(root.selectedEntry, steps);
            return true;
        }
        return false;
    }

    function wheel(delta: real) {
        root.wheelTravel += delta;
        const steps = Math.trunc(root.wheelTravel / Style.quickMenu.wheelStep);
        if (steps === 0)
            return;

        root.wheelTravel -= steps * Style.quickMenu.wheelStep;
        if (!root.editing && !root.adjust(steps))
            root.scrollList(-steps);
    }

    // The wheel over a list's slot (the apps', the clipboard's): into the
    // list on its first row, then along its rows, with the pointer left
    // where it is. Letting the key go uses the row, as if pointed at.
    function scrollList(rows: int) {
        const slot = root.selectedArea === "ring" ? root.selectedIndex : root.wheelSlot;
        if (slot < 0 || root.items.kindOf(root.slots[slot] ?? "") !== "list")
            return;

        if (root.selectedArea === "panel" && root.arcSlot === slot) {
            root.stepRow(rows);
            return;
        }
        switcher.stop();
        root.wheelSlot = slot;
        root.arcSlot = slot;
        root.arcEntered = true;
        root.select("panel", 0, true);
        root.list?.show(0);
    }

    focus: true
    Component.onCompleted: {
        root.openedAt = Date.now();
        root.pinned = !root.holding;
        root.armed = !root.launcher && Math.hypot(root.origin.x - root.center.x, root.origin.y - root.center.y) < Style.quickMenu.centerRadius * root.zoom;
        if (root.launcher && root.appsSlot >= 0)
            root.openTree(root.appsSlot, "key");
    }
    Keys.onPressed: event => {
        const how = root.holding ? "held" : "key";
        root.keysShown = true;
        if (root.typing && root.type(event)) {
            event.accepted = true;
            return;
        }
        switch (event.key) {
        case Qt.Key_Escape:
            if (!root.back())
                root.closeRequested();
            break;
        case Qt.Key_Backspace:
            root.back();
            break;
        case Qt.Key_Left:
        case Qt.Key_Backtab:
            root.stepSelection(-1);
            break;
        case Qt.Key_Right:
        case Qt.Key_Tab:
            root.stepSelection(1);
            break;
        case Qt.Key_Up:
            if (root.selectedArea === "panel")
                root.stepRow(-1);
            else if (!root.adjust(1) && ["category", "list"].includes(root.selectedItem.kind))
                root.openTree(root.selectedIndex, "key");
            break;
        case Qt.Key_Down:
            if (root.selectedArea === "panel")
                root.stepRow(1);
            else if (!root.adjust(-1))
                root.back();
            break;
        case Qt.Key_Delete:
            if (root.selectedArea !== "panel" || root.list === null)
                return;
            root.list.forget(root.selectedIndex);
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Space:
            if (root.selectedArea === "")
                root.stepSelection(1);
            else
                root.use(how);
            break;
        case Qt.Key_Comma:
            root.select("settings", -1, true);
            root.use(how);
            break;
        default:
            if (event.key >= Qt.Key_1 && event.key < Qt.Key_1 + root.count && !root.editing) {
                root.select("ring", event.key - Qt.Key_1, true);
                root.use(how);
            } else if (/^[a-z]$/i.test(event.text) && !root.editing) {
                root.useLetter(event.text.toUpperCase(), how);
            } else {
                return;
            }
        }
        event.accepted = true;
    }

    Timer {
        id: switcher

        interval: Style.quickMenu.switchDelay
        onTriggered: {
            root.arcSlot = root.pendingSlot;
            root.arcEntered = false;
        }
    }

    Timer {
        id: keyDelay

        interval: Style.quickMenu.keyDelay
        running: true
        onTriggered: root.keysShown = true
    }

    Timer {
        id: confirmation

        interval: Style.popup.confirmTimeout
        onTriggered: root.confirming = ""
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPositionChanged: mouse => root.move(mouse.x, mouse.y)
        onPressed: mouse => {
            if (!root.editing || mouse.button !== Qt.LeftButton)
                return;
            const target = root.hit(mouse.x, mouse.y);
            root.dragFrom = target.area === "ring" ? target.index : -1;
        }
        // Editing, a slot dropped on another swaps them.
        onReleased: mouse => {
            const target = root.hit(mouse.x, mouse.y);
            root.dragged = root.dragFrom >= 0 && target.area === "ring" && target.index !== root.dragFrom;
            if (root.dragged) {
                QuickMenu.swap(root.dragFrom, target.index);
                root.editSlot = target.index;
            }
            root.dragFrom = -1;
        }
        onClicked: mouse => {
            if (root.dragged)
                root.dragged = false;
            else if (mouse.button === Qt.RightButton && !root.back())
                root.closeRequested();
            else if (mouse.button !== Qt.RightButton)
                root.click(mouse.x, mouse.y);
        }
        onWheel: wheel => root.wheel(wheel.angleDelta.y)
    }

    Item {
        x: root.center.x
        y: root.center.y
        scale: root.zoom
        transformOrigin: Item.TopLeft

        Item {
            id: menu

            transformOrigin: Item.TopLeft

            NumberAnimation on opacity {
                running: !root.playful
                from: 0
                to: 1
                duration: Style.animation.normal
                easing.type: Easing.OutCubic
            }

            NumberAnimation on scale {
                running: !root.playful
                from: Style.quickMenu.calmFrom
                to: 1
                duration: Style.animation.normal
                easing.type: Easing.OutCubic
            }

            // Halo's disc, which springs in as a whole, its slots after it.
            Rectangle {
                id: disc

                property real reveal: root.playful ? 0 : 1

                visible: !root.orbit
                x: -Style.quickMenu.ringOuter
                y: -Style.quickMenu.ringOuter
                width: Style.quickMenu.ringOuter * 2
                height: Style.quickMenu.ringOuter * 2
                radius: Style.quickMenu.ringOuter
                color: Colors.base.surface
                border.width: Style.border.width
                border.color: Colors.base.border
                scale: Style.quickMenu.popFrom + (1 - Style.quickMenu.popFrom) * disc.reveal
                opacity: Math.min(1, disc.reveal * 2)

                NumberAnimation on reveal {
                    running: root.playful
                    to: 1
                    duration: Style.quickMenu.spring
                    easing.type: Easing.OutBack
                    easing.overshoot: Style.quickMenu.overshoot
                }
            }

            // Orbit's track for the slots.
            Shape {
                visible: root.orbit
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Colors.icon.track
                    strokeWidth: Style.border.width

                    PathAngleArc {
                        radiusX: root.slotRadius
                        radiusY: root.slotRadius
                        startAngle: 0
                        sweepAngle: 360
                    }
                }
            }

            // Under a category's items: Halo's band, Orbit's track. Each
            // category's comes anew.
            Item {
                id: arcBack

                property real reveal: 0

                function pop() {
                    arcBack.reveal = 0;
                    arcAppear.restart();
                }

                visible: root.arcItems.length > 0
                opacity: arcBack.reveal
                transformOrigin: Item.TopLeft
                scale: Style.quickMenu.calmFrom + (1 - Style.quickMenu.calmFrom) * Math.min(1, arcBack.reveal)

                Connections {
                    function onArcSlotChanged() {
                        arcBack.pop();
                    }

                    target: root
                }

                NumberAnimation {
                    id: arcAppear

                    target: arcBack
                    property: "reveal"
                    to: 1
                    duration: root.playful ? Style.quickMenu.spring : Style.animation.normal
                    easing.type: Easing.OutCubic
                }

                RingSector {
                    visible: !root.orbit
                    inner: Style.quickMenu.arcInner
                    outer: Style.quickMenu.arcOuter
                    from: root.arcStart
                    to: root.arcStart + root.span * root.arcItems.length
                    corner: Style.bar.radius
                    fillColor: Colors.base.surface
                    strokeColor: Colors.base.border
                }

                Shape {
                    visible: root.orbit
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Colors.icon.track
                        strokeWidth: Style.border.width

                        PathAngleArc {
                            radiusX: root.itemRadius
                            radiusY: root.itemRadius
                            startAngle: root.arcStart - 90
                            sweepAngle: root.span * root.arcItems.length
                        }
                    }
                }
            }

            // Orbit's line from the hub to the selected slot's button, and on
            // from there to the item selected in its arc.
            Shape {
                id: connector

                readonly property real angle: root.selectedSlot * root.step
                readonly property point hubEdge: root.polar(Style.quickMenu.centerRadius, connector.angle)
                readonly property point slotEdge: root.polar(root.slotRadius - Style.quickMenu.buttonSize * Style.quickMenu.selectedScale / 2, connector.angle)
                readonly property point slotAt: root.polar(root.slotRadius, connector.angle)
                readonly property point itemAt: root.polar(root.itemRadius, root.arcAngle(root.selectedIndex) + root.span / 2)
                readonly property real length: Math.max(1, Math.hypot(connector.itemAt.x - connector.slotAt.x, connector.itemAt.y - connector.slotAt.y))
                readonly property real leave: Style.quickMenu.buttonSize * Style.quickMenu.selectedScale / 2 / connector.length
                readonly property real arrive: 1 - Style.quickMenu.itemButtonSize * Style.quickMenu.selectedScale / 2 / connector.length

                visible: root.orbit && !root.editing && root.selectedSlot >= 0
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Colors.accent.primary
                    strokeWidth: Style.quickMenu.connectorWidth
                    capStyle: ShapePath.RoundCap
                    startX: connector.hubEdge.x
                    startY: connector.hubEdge.y

                    PathLine {
                        x: connector.slotEdge.x
                        y: connector.slotEdge.y
                    }
                }

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: root.selectedArea === "arc" ? Colors.accent.primary : "transparent"
                    strokeWidth: Style.quickMenu.connectorWidth
                    capStyle: ShapePath.RoundCap
                    startX: connector.slotAt.x + (connector.itemAt.x - connector.slotAt.x) * connector.leave
                    startY: connector.slotAt.y + (connector.itemAt.y - connector.slotAt.y) * connector.leave

                    PathLine {
                        x: connector.slotAt.x + (connector.itemAt.x - connector.slotAt.x) * connector.arrive
                        y: connector.slotAt.y + (connector.itemAt.y - connector.slotAt.y) * connector.arrive
                    }
                }
            }

            Repeater {
                model: root.count

                delegate: Item {
                    id: slot

                    required property int index
                    readonly property string entry: root.slots[slot.index] ?? ""
                    readonly property var item: root.items.describe(slot.entry)
                    readonly property real angle: slot.index * root.step
                    readonly property bool selected: (root.selectedArea === "ring" && root.selectedIndex === slot.index) || (root.editing && root.editSlot === slot.index)
                    readonly property bool raised: root.arcSlot === slot.index
                    readonly property point at: root.polar(root.slotRadius, slot.angle)
                    readonly property string key: root.editing ? "" : root.ringKeys[slot.index] ?? ""
                    readonly property bool confirming: root.confirming !== "" && root.confirming === slot.entry && root.selectedArea === "ring"
                    readonly property bool faded: root.focusedOnArc && !slot.raised && !slot.selected
                    property real reveal: root.playful ? 0 : 1

                    transformOrigin: Item.TopLeft
                    scale: Style.quickMenu.popFrom + (1 - Style.quickMenu.popFrom) * slot.reveal
                    opacity: Math.min(1, slot.reveal * 2)

                    SequentialAnimation on reveal {
                        running: root.playful

                        PauseAnimation {
                            duration: slot.index * Style.quickMenu.stagger
                        }

                        NumberAnimation {
                            to: 1
                            duration: Style.quickMenu.spring
                            easing.type: Easing.OutBack
                            easing.overshoot: Style.quickMenu.overshoot
                        }
                    }

                    RingSector {
                        visible: !root.orbit
                        inner: Style.quickMenu.centerRadius + Style.quickMenu.inset
                        outer: Style.quickMenu.ringOuter - Style.quickMenu.inset
                        from: slot.angle - root.step / 2
                        to: slot.angle + root.step / 2
                        edge: Style.quickMenu.inset
                        corner: Style.popup.rowRadius
                        fillColor: slot.selected ? Colors.pill.selected : slot.raised ? Colors.base.hover : "transparent"
                        strokeColor: root.editing || slot.item.kind === "empty" ? Colors.base.border : "transparent"
                        dashed: true
                    }

                    RingItem {
                        visible: !root.orbit
                        x: slot.at.x - width / 2
                        y: slot.at.y - height / 2
                        opacity: slot.faded ? Style.quickMenu.dimmed : 1
                        item: slot.item
                        angle: slot.angle
                        showLabel: QuickMenu.labels
                        labelAbove: root.labelAbove(slot.angle)
                        room: root.room(root.labelPoint(slot.at, slot.angle), Style.quickMenu.centerRadius, Style.quickMenu.ringOuter, slot.angle - root.step / 2, slot.angle + root.step / 2)
                        key: slot.key
                        keyShown: root.keysShown
                        selected: slot.selected
                        confirming: slot.confirming
                    }

                    OrbitButton {
                        visible: root.orbit
                        x: slot.at.x - width / 2
                        y: slot.at.y - height / 2
                        opacity: slot.faded ? Style.quickMenu.dimmed : 1
                        item: slot.item
                        angle: slot.angle
                        selected: root.selectedSlot === slot.index || (root.editing && root.editSlot === slot.index)
                        dashed: root.editing
                        confirming: slot.confirming
                        key: slot.key
                        keyShown: root.keysShown
                    }
                }
            }

            Repeater {
                model: root.arcItems.length

                delegate: Item {
                    id: arcItem

                    required property int index
                    readonly property string entry: root.arcItems[arcItem.index] ?? ""
                    readonly property var item: root.items.describe(arcItem.entry)
                    readonly property real angle: root.arcAngle(arcItem.index) + root.span / 2
                    readonly property bool selected: root.selectedArea === "arc" && root.selectedIndex === arcItem.index
                    readonly property point at: root.polar(root.itemRadius, arcItem.angle)
                    // Out of its category's slot, where playful.
                    readonly property point from: root.polar(root.slotRadius, root.arcSlot * root.step)
                    readonly property real travel: root.playful ? 1 - arcItem.reveal : 0
                    readonly property point shown: Qt.point(arcItem.at.x + (arcItem.from.x - arcItem.at.x) * arcItem.travel, arcItem.at.y + (arcItem.from.y - arcItem.at.y) * arcItem.travel)
                    property real reveal: 0

                    function pop() {
                        arcItem.reveal = 0;
                        appear.restart();
                    }

                    opacity: arcItem.reveal
                    Component.onCompleted: arcItem.pop()

                    Connections {
                        function onArcSlotChanged() {
                            arcItem.pop();
                        }

                        target: root
                    }

                    SequentialAnimation {
                        id: appear

                        PauseAnimation {
                            duration: root.playful ? arcItem.index * Style.quickMenu.itemStagger : 0
                        }

                        NumberAnimation {
                            target: arcItem
                            property: "reveal"
                            to: 1
                            duration: root.playful ? Style.quickMenu.spring : Style.animation.normal
                            easing.type: root.playful ? Easing.OutBack : Easing.OutCubic
                            easing.overshoot: Style.quickMenu.overshoot
                        }
                    }

                    RingSector {
                        visible: !root.orbit
                        transformOrigin: Item.TopLeft
                        scale: 1 - (1 - Style.quickMenu.calmFrom) * arcItem.travel * 3
                        inner: Style.quickMenu.arcInner + Style.quickMenu.inset
                        outer: Style.quickMenu.arcOuter - Style.quickMenu.inset
                        from: root.arcAngle(arcItem.index)
                        to: root.arcAngle(arcItem.index) + root.span
                        edge: Style.quickMenu.inset
                        corner: Style.popup.rowRadius
                        fillColor: arcItem.selected ? Colors.pill.selected : "transparent"
                    }

                    RingItem {
                        visible: !root.orbit
                        x: arcItem.shown.x - width / 2
                        y: arcItem.shown.y - height / 2
                        scale: 1 - (1 - Style.quickMenu.popFrom) * arcItem.travel
                        item: arcItem.item
                        angle: arcItem.angle
                        showLabel: QuickMenu.labels
                        labelAbove: root.labelAbove(arcItem.angle)
                        room: root.room(root.labelPoint(arcItem.at, arcItem.angle), Style.quickMenu.arcInner, Style.quickMenu.arcOuter, root.arcAngle(arcItem.index), root.arcAngle(arcItem.index) + root.span)
                        key: root.arcKeys[arcItem.index] ?? ""
                        keyShown: root.keysShown
                        selected: arcItem.selected
                        confirming: root.confirming !== "" && root.confirming === arcItem.entry
                    }

                    OrbitButton {
                        visible: root.orbit
                        x: arcItem.shown.x - width / 2
                        y: arcItem.shown.y - height / 2
                        size: Style.quickMenu.itemButtonSize
                        item: arcItem.item
                        angle: arcItem.angle
                        selected: arcItem.selected
                        confirming: root.confirming !== "" && root.confirming === arcItem.entry
                        key: root.arcKeys[arcItem.index] ?? ""
                        keyShown: root.keysShown
                    }
                }
            }

            // A list's entries, out from its slot.
            Loader {
                id: listPanel

                active: root.listOut
                sourceComponent: root.slots[root.arcSlot] === "item:apps" ? appsList : clipboardList
            }

            Loader {
                id: editorPanel

                active: root.editing

                sourceComponent: QuickMenuEditor {
                    side: root.editorSide
                    orbit: root.orbit
                    items: root.items
                    slot: root.editSlot
                    onDone: {
                        root.editing = false;
                        root.editSlot = -1;
                    }
                    onSettingsRequested: {
                        root.closeRequested();
                        SettingsState.show("keyboard");
                    }
                }
            }

            RingHub {
                id: hub

                property real reveal: root.playful ? 0 : 1

                scale: Style.quickMenu.popFrom + (1 - Style.quickMenu.popFrom) * hub.reveal
                framed: root.orbit
                halves: !root.editing && ["", "settings", "edit"].includes(root.selectedArea)
                editing: root.editing
                lit: ["settings", "edit", "done"].includes(root.selectedArea) ? root.selectedArea : ""
                title: root.selectedItem.label ?? ""
                // Asked again: what to do, in red where it ends something.
                detail: root.confirming !== "" && root.confirming === root.selectedEntry ? "Again to confirm" : root.selectedItem.detail ?? ""
                danger: root.confirming !== "" && root.selectedItem.danger === true

                NumberAnimation on reveal {
                    running: root.playful
                    to: 1
                    duration: Style.quickMenu.spring
                    easing.type: Easing.OutBack
                    easing.overshoot: Style.quickMenu.overshoot
                }
            }
        }
    }

    Component {
        id: appsList

        QuickMenuApps {
            side: root.sideOf(root.arcSlot)
            level: -Style.quickMenu.arcInner * Math.cos(root.arcSlot * root.step * Math.PI / 180)
            current: root.selectedArea === "panel" ? root.selectedIndex : -1
            typing: root.typing
            // A launched app or a copied answer: the menu goes.
            onPicked: root.closeRequested()
        }
    }

    Component {
        id: clipboardList

        QuickMenuClipboard {
            side: root.sideOf(root.arcSlot)
            level: -Style.quickMenu.arcInner * Math.cos(root.arcSlot * root.step * Math.PI / 180)
            current: root.selectedArea === "panel" ? root.selectedIndex : -1
            // A copied entry is to be pasted: the menu goes.
            onPicked: root.closeRequested()
        }
    }
}
