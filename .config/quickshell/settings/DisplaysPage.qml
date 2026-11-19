import "../panels"
import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// The monitors as Hyprland has them (`hyprctl monitors all`), arranged by
// dragging. Changes wait here until applied together; DisplayChange takes them
// back unless kept, and what is kept monitors.lua applies at every login.
ScrollPage {
    id: root

    property var monitors: []
    // Monitor name -> the fields changed but not applied yet.
    property var pending: ({})
    property string selected: ""
    // What displays.py kept, as hl.monitor rules.
    property var kept: []
    readonly property bool hasPending: Object.keys(root.pending).length > 0
    readonly property var enabledMonitors: root.monitors.filter(monitor => !root.effective(monitor).disabled)
    readonly property var current: root.monitors.find(monitor => monitor.name === root.selected) || (root.monitors.length > 0 ? root.monitors[0] : null)
    readonly property var selectedState: root.current !== null ? root.effective(root.current) : null
    readonly property bool selectedOff: root.selectedState?.disabled ?? false
    readonly property var keptRule: root.current !== null ? root.kept.find(rule => rule.output === root.selector(root.current)) || null : null

    function read() {
        if (!monitorReader.running)
            monitorReader.running = true;
    }

    function rateText(rate: real): string {
        return String(Math.round(rate * 100) / 100);
    }

    function modeText(width: int, height: int, rate: real): string {
        return width + "x" + height + "@" + root.rateText(rate);
    }

    // How a rule names a monitor: by make, model and serial where Hyprland
    // has them, so a kept rule follows the monitor to another port.
    function selector(monitor): string {
        return monitor.description !== "" ? "desc:" + monitor.description : monitor.name;
    }

    function keptFor(monitor) {
        return root.kept.find(rule => rule.output === root.selector(monitor)) || null;
    }

    function live(monitor) {
        const rule = root.keptFor(monitor);
        return {
            width: monitor.width,
            height: monitor.height,
            rate: monitor.refreshRate,
            x: monitor.x,
            y: monitor.y,
            scale: monitor.scale,
            transform: monitor.transform,
            vrr: rule !== null && rule.vrr !== undefined ? rule.vrr : (monitor.vrr ? 1 : 0),
            disabled: monitor.disabled
        };
    }

    function effective(monitor) {
        return Object.assign(root.live(monitor), root.pending[monitor.name] || {});
    }

    // Logical size, as the layout counts it: scaled, and turned on its side.
    function footprint(state) {
        const width = state.width / state.scale;
        const height = state.height / state.scale;
        return state.transform % 2 === 1 ? {
            width: height,
            height: width
        } : {
            width: width,
            height: height
        };
    }

    // Changed fields, minus those back at the live value.
    function change(name: string, fields) {
        const monitor = root.monitors.find(candidate => candidate.name === name);
        if (monitor === undefined)
            return;

        const live = root.live(monitor);
        const merged = Object.assign({}, root.pending[name] || {}, fields);
        for (const key of Object.keys(merged)) {
            const same = typeof merged[key] === "number" ? Math.abs(merged[key] - live[key]) < 0.001 : merged[key] === live[key];
            if (same)
                delete merged[key];
        }
        const next = Object.assign({}, root.pending);
        if (Object.keys(merged).length > 0)
            next[name] = merged;
        else
            delete next[name];
        root.pending = next;
    }

    function rule(monitor, state, withVrr, withDisabled) {
        const result = {
            output: root.selector(monitor),
            mode: root.modeText(state.width, state.height, state.rate),
            position: Math.round(state.x) + "x" + Math.round(state.y),
            scale: state.scale,
            transform: state.transform
        };
        if (withVrr)
            result.vrr = state.vrr;

        if (withDisabled)
            result.disabled = state.disabled;

        return result;
    }

    function applyPending() {
        const applied = [];
        const previous = [];
        for (const name of Object.keys(root.pending)) {
            const monitor = root.monitors.find(candidate => candidate.name === name);
            if (monitor === undefined)
                continue;

            const kept = root.keptFor(monitor);
            const withVrr = root.pending[name].vrr !== undefined || (kept !== null && kept.vrr !== undefined);
            const withDisabled = root.pending[name].disabled !== undefined || monitor.disabled;
            applied.push(root.rule(monitor, root.effective(monitor), withVrr, withDisabled));
            previous.push(root.rule(monitor, root.live(monitor), withVrr, withDisabled));
        }
        root.pending = {};
        DisplayChange.apply(applied, previous);
    }

    // A monitor's place in whole logical pixels, as Hyprland lays them out.
    function box(monitor) {
        const state = root.effective(monitor);
        const size = root.footprint(state);
        return {
            name: monitor.name,
            x: Math.round(state.x),
            y: Math.round(state.y),
            width: Math.round(size.width),
            height: Math.round(size.height)
        };
    }

    function others(name: string): var {
        return root.enabledMonitors.filter(monitor => monitor.name !== name).map(monitor => root.box(monitor));
    }

    function overlaps(a, b): bool {
        return a.x < b.x + b.width && a.x + a.width > b.x && a.y < b.y + b.height && a.y + a.height > b.y;
    }

    // Which side of b a sits flush against, sharing some of the edge; "" when
    // they only meet at a corner or not at all.
    function side(a, b): string {
        const alongX = Math.min(a.x + a.width, b.x + b.width) - Math.max(a.x, b.x) > 0;
        const alongY = Math.min(a.y + a.height, b.y + b.height) - Math.max(a.y, b.y) > 0;
        if (alongY && a.x + a.width === b.x)
            return "left";
        if (alongY && b.x + b.width === a.x)
            return "right";
        if (alongX && a.y + a.height === b.y)
            return "above";
        if (alongX && b.y + b.height === a.y)
            return "below";
        return "";
    }

    // The monitors in pieces, each joined across touching edges.
    function groups(boxes) {
        const result = [];
        const seen = [];
        for (const start of boxes) {
            if (seen.includes(start))
                continue;

            const group = [start];
            seen.push(start);
            for (let index = 0; index < group.length; index++) {
                for (const other of boxes) {
                    if (!seen.includes(other) && root.side(group[index], other) !== "") {
                        seen.push(other);
                        group.push(other);
                    }
                }
            }
            result.push(group);
        }
        return result;
    }

    // Along a shared edge, where a sits against b: lined up at the top or
    // left ("start"), the bottom or right ("end"), centred, or at an offset.
    function anchor(a, b, side: string): var {
        const across = side === "left" || side === "right";
        const start = across ? a.y - b.y : a.x - b.x;
        const free = across ? b.height - a.height : b.width - a.width;
        if (start === 0)
            return {
                kind: "start",
                offset: 0
            };
        if (start === free)
            return {
                kind: "end",
                offset: 0
            };
        if (Math.abs(start * 2 - free) <= 1)
            return {
                kind: "center",
                offset: 0
            };
        return {
            kind: "offset",
            offset: start
        };
    }

    // How a monitor sits against the ones it touches, to keep when it changes size.
    function relations(name: string): var {
        const self = root.box(root.monitors.find(monitor => monitor.name === name));
        const result = [];
        for (const other of root.others(name)) {
            const side = root.side(self, other);
            if (side !== "")
                result.push({
                    other: other.name,
                    side: side,
                    anchor: root.anchor(self, other, side)
                });
        }
        return result;
    }

    // Where a can sit along b's edge, as its top or left: sharing at least a
    // quarter of the shorter edge, so the pointer can cross between them.
    function along(wanted: real, start: int, size: int, otherSize: int): int {
        const share = Math.ceil(Math.min(size, otherSize) / 4);
        return Math.max(start - size + share, Math.min(start + otherSize - share, Math.round(wanted)));
    }

    // Where a slides along b's edge: anywhere it keeps enough of the edge,
    // snapping to either end or the middle when within a twentieth.
    function slide(wanted: real, start: int, size: int, otherSize: int): var {
        const lined = [start, start + otherSize - size, Math.round(start + (otherSize - size) / 2)];
        const threshold = Math.max(size, otherSize) / 20;
        const snapped = lined.find(candidate => Math.abs(wanted - candidate) < threshold);
        return [snapped !== undefined ? snapped : root.along(wanted, start, size, otherSize)].concat(lined);
    }

    // How far to move a group of monitors, wanted dx,dy, so one of them
    // sits flush against a side of a fixed one, sharing some of that edge
    // (Hyprland finds monitors in a direction only across touching edges)
    // and covering none. A single monitor keeps a relation from `keep` if
    // it can, else the nearest place wins. Null if nothing fits.
    function fit(moving, fixed, dx: real, dy: real, keep): var {
        if (fixed.length === 0)
            return {
                dx: 0,
                dy: 0,
                kept: false
            };

        let best = null;
        for (const mover of moving) {
            for (const other of fixed) {
                for (const side of ["left", "right", "above", "below"]) {
                    const across = side === "left" || side === "right";
                    const flush = side === "left" ? other.x - mover.width : side === "right" ? other.x + other.width : side === "above" ? other.y - mover.height : other.y + other.height;
                    const start = across ? other.y : other.x;
                    const size = across ? mover.height : mover.width;
                    const otherSize = across ? other.height : other.width;
                    const places = root.slide((across ? mover.y + dy : mover.x + dx), start, size, otherSize).map(value => ({
                                value: value,
                                kept: false
                            }));
                    const relation = moving.length === 1 ? keep.find(candidate => candidate.other === other.name && candidate.side === side) : undefined;
                    if (relation !== undefined) {
                        const kind = relation.anchor.kind;
                        const value = kind === "start" ? start : kind === "end" ? start + otherSize - size : kind === "center" ? Math.round(start + (otherSize - size) / 2) : root.along(start + relation.anchor.offset, start, size, otherSize);
                        places.unshift({
                            value: value,
                            kept: true
                        });
                    }
                    for (const place of places) {
                        const shift = across ? {
                            dx: flush - mover.x,
                            dy: place.value - mover.y
                        } : {
                            dx: place.value - mover.x,
                            dy: flush - mover.y
                        };
                        const covers = moving.some(one => fixed.some(two => root.overlaps({
                                    x: one.x + shift.dx,
                                    y: one.y + shift.dy,
                                    width: one.width,
                                    height: one.height
                                }, two)));
                        if (covers)
                            continue;

                        const score = [place.kept ? 0 : 1, Math.hypot(shift.dx - dx, shift.dy - dy)];
                        if (best === null || score[0] < best.score[0] || (score[0] === best.score[0] && score[1] < best.score[1]))
                            best = {
                                dx: shift.dx,
                                dy: shift.dy,
                                kept: place.kept,
                                score: score
                            };
                    }
                }
            }
        }
        return best;
    }

    function move(boxes, shift) {
        for (const one of boxes)
            root.change(one.name, {
                x: one.x + shift.dx,
                y: one.y + shift.dy
            });
    }

    // After any move: monitors cut off from the rest, when one between them
    // moved or turned off, move up against the others one group at a time;
    // then the whole layout shifts to start at 0,0.
    function settle() {
        for (let round = 0; round < root.monitors.length; round++) {
            const boxes = root.enabledMonitors.map(monitor => root.box(monitor));
            const parts = root.groups(boxes).sort((a, b) => b.length - a.length);
            if (parts.length < 2)
                break;

            const group = parts[parts.length - 1];
            const shift = root.fit(group, boxes.filter(one => !group.includes(one)), 0, 0, []);
            if (shift === null)
                break;

            root.move(group, shift);
        }
        const boxes = root.enabledMonitors.map(monitor => root.box(monitor));
        const left = Math.min(...boxes.map(one => one.x));
        const top = Math.min(...boxes.map(one => one.y));
        root.move(boxes, {
            dx: -left,
            dy: -top
        });
    }

    function drop(name: string, dx: real, dy: real) {
        const moving = root.box(root.monitors.find(monitor => monitor.name === name));
        const shift = root.fit([moving], root.others(name), dx, dy, []);
        if (shift === null)
            return;

        root.move([moving], shift);
        root.settle();
    }

    // A change that can resize a monitor or turn it on or off. A resized
    // monitor keeps how it sat against a neighbour (lined up, centred or at
    // an offset) where that covers nothing; else it stays put and those past
    // its right or bottom edge move along with that edge; else it takes the
    // nearest free place. A monitor turned on takes the nearest free place.
    function reshape(name: string, fields) {
        const monitor = root.monitors.find(candidate => candidate.name === name);
        if (monitor === undefined)
            return;

        const wasOn = !root.effective(monitor).disabled;
        const before = root.box(monitor);
        const keep = wasOn ? root.relations(name) : [];
        root.change(name, fields);
        if (!root.effective(monitor).disabled) {
            const after = root.box(monitor);
            const others = root.others(name);
            const kept = root.fit([after], others, 0, 0, keep);
            const pushed = others.map(other => Object.assign({}, other, {
                    x: other.x >= before.x + before.width ? other.x + after.width - before.width : other.x,
                    y: other.y >= before.y + before.height ? other.y + after.height - before.height : other.y
                }));
            const layout = pushed.concat([after]);
            const apart = layout.every(a => layout.every(b => a === b || !root.overlaps(a, b)));
            if (wasOn && !(kept !== null && kept.kept) && apart && root.groups(layout).length === 1) {
                for (const other of pushed)
                    root.change(other.name, {
                        x: other.x,
                        y: other.y
                    });
            } else if (kept !== null) {
                root.move([after], kept);
            }
        }
        root.settle();
    }

    function resolutions(monitor) {
        const seen = [];
        const choices = [];
        for (const mode of monitor.modes) {
            const value = mode.width + "x" + mode.height;
            if (!seen.includes(value)) {
                seen.push(value);
                choices.push({
                    label: mode.width + " × " + mode.height,
                    value: value
                });
            }
        }
        const state = root.effective(monitor);
        const current = state.width + "x" + state.height;
        if (!seen.includes(current))
            choices.unshift({
                label: state.width + " × " + state.height,
                value: current
            });

        return choices;
    }

    function rates(monitor) {
        const state = root.effective(monitor);
        const found = monitor.modes.filter(mode => mode.width === state.width && mode.height === state.height).map(mode => mode.rate);
        if (!found.some(rate => Math.abs(rate - state.rate) < 0.01))
            found.push(state.rate);

        const unique = [];
        for (const rate of found.sort((a, b) => b - a)) {
            if (!unique.some(known => root.rateText(known) === root.rateText(rate)))
                unique.push(rate);
        }
        return unique;
    }

    // Scales that leave a whole number of logical pixels, in 1/120 steps as
    // fractional scaling counts them; Hyprland would correct any other.
    function scales(monitor) {
        const state = root.effective(monitor);
        const found = [1, 1.25, 4 / 3, 1.5, 1.6, 5 / 3, 1.75, 2, 2.5, 3].filter(scale => {
            const width = state.width / scale;
            const height = state.height / scale;
            return width >= 960 && Math.abs(width - Math.round(width)) < 0.01 && Math.abs(height - Math.round(height)) < 0.01 && Math.abs(scale * 120 - Math.round(scale * 120)) < 0.01;
        });
        if (!found.some(scale => Math.abs(scale - state.scale) < 0.001))
            found.push(state.scale);

        return found.sort((a, b) => a - b);
    }

    function pickResolution(value) {
        const parts = value.split("x");
        const width = Number(parts[0]);
        const height = Number(parts[1]);
        const state = root.effective(root.current);
        const matching = root.current.modes.filter(mode => mode.width === width && mode.height === height);
        // The rate it has if this resolution offers it, the highest otherwise.
        const keep = matching.find(mode => Math.abs(mode.rate - state.rate) < 0.01);
        const rate = keep !== undefined ? keep.rate : matching.reduce((best, mode) => Math.max(best, mode.rate), state.rate);
        root.reshape(root.current.name, {
            width: width,
            height: height,
            rate: rate
        });
    }

    Component.onCompleted: root.read()

    Connections {
        function onRawEvent(event: HyprlandEvent) {
            if (["monitoradded", "monitoraddedv2", "monitorremoved", "monitorremovedv2", "configreloaded"].includes(event.name))
                root.read();
        }

        target: Hyprland
    }

    Connections {
        function onSettled() {
            reread.restart();
        }

        target: DisplayChange
    }

    // Hyprland applies monitor rules on its next refresh, not by the time
    // hyprctl returns.
    Timer {
        id: reread

        interval: Style.settings.rereadDelay
        onTriggered: root.read()
    }

    Process {
        id: monitorReader

        command: ["hyprctl", "monitors", "all", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text).map(monitor => {
                        const modes = [];
                        for (const mode of monitor.availableModes || []) {
                            const match = /^(\d+)x(\d+)@([\d.]+)Hz$/.exec(mode);
                            if (match !== null)
                                modes.push({
                                    width: Number(match[1]),
                                    height: Number(match[2]),
                                    rate: Number(match[3])
                                });
                        }
                        return Object.assign({}, monitor, {
                            modes: modes
                        });
                    }).sort((left, right) => left.x - right.x || left.y - right.y);
                } catch (error) {
                    console.warn("displays: hyprctl printed no monitors:", error);
                }
            }
        }
    }

    FileView {
        path: StateFiles.path("monitors.json")
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.kept = JSON.parse(text());
            } catch (error) {
                root.kept = [];
            }
        }
        onLoadFailed: root.kept = []
    }

    Section {
        visible: root.monitors.length > 0
        title: "ARRANGEMENT"

        Card {
            id: map

            readonly property var bounds: {
                let left = Infinity;
                let top = Infinity;
                let right = -Infinity;
                let bottom = -Infinity;
                for (const monitor of root.enabledMonitors) {
                    const state = root.effective(monitor);
                    const size = root.footprint(state);
                    left = Math.min(left, state.x);
                    top = Math.min(top, state.y);
                    right = Math.max(right, state.x + size.width);
                    bottom = Math.max(bottom, state.y + size.height);
                }
                return left === Infinity ? {
                    x: 0,
                    y: 0,
                    width: 1,
                    height: 1
                } : {
                    x: left,
                    y: top,
                    width: right - left,
                    height: bottom - top
                };
            }
            readonly property real factor: Math.min((width - Style.bar.padding * 2) / bounds.width, (height - Style.bar.padding * 2) / bounds.height)

            width: root.columnWidth
            height: Style.settings.arrangementHeight

            Repeater {
                model: root.enabledMonitors

                delegate: Rectangle {
                    id: tile

                    required property var modelData
                    readonly property var tileState: root.effective(tile.modelData)
                    readonly property var size: root.footprint(tile.tileState)
                    readonly property bool chosen: root.current !== null && tile.modelData.name === root.current.name
                    property real shiftX: 0
                    property real shiftY: 0

                    x: (map.width - map.bounds.width * map.factor) / 2 + (tile.tileState.x - map.bounds.x) * map.factor + tile.shiftX
                    y: (map.height - map.bounds.height * map.factor) / 2 + (tile.tileState.y - map.bounds.y) * map.factor + tile.shiftY
                    width: tile.size.width * map.factor
                    height: tile.size.height * map.factor
                    z: tileArea.pressed ? 1 : 0
                    radius: Style.popup.rowRadius
                    color: tile.chosen ? Colors.pill.selected : Colors.base.hover
                    border.width: tile.chosen ? Style.settings.swatchRing : Style.border.width
                    border.color: tile.chosen ? Colors.accent.primary : Colors.base.border

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - Style.widgets.padding * 2

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: tile.modelData.name
                            textFormat: Text.PlainText
                            color: Colors.text.base
                            font.family: Style.text.font
                            font.pixelSize: Style.text.size
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: tile.modelData.model || ""
                            textFormat: Text.PlainText
                            color: Colors.text.muted
                            font.family: Style.text.font
                            font.pixelSize: Style.text.smallSize
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: tileArea

                        property point start

                        anchors.fill: parent
                        cursorShape: root.enabledMonitors.length > 1 ? Qt.SizeAllCursor : Qt.PointingHandCursor
                        onPressed: mouse => {
                            root.selected = tile.modelData.name;
                            tileArea.start = tileArea.mapToItem(map, mouse.x, mouse.y);
                        }
                        onPositionChanged: mouse => {
                            if (root.enabledMonitors.length < 2 || DisplayChange.waiting)
                                return;

                            const point = tileArea.mapToItem(map, mouse.x, mouse.y);
                            tile.shiftX = point.x - tileArea.start.x;
                            tile.shiftY = point.y - tileArea.start.y;
                        }
                        onReleased: {
                            if (Math.abs(tile.shiftX) > 2 || Math.abs(tile.shiftY) > 2)
                                root.drop(tile.modelData.name, tile.shiftX / map.factor, tile.shiftY / map.factor);

                            tile.shiftX = 0;
                            tile.shiftY = 0;
                        }
                    }
                }
            }
        }

        Text {
            width: root.columnWidth
            text: root.enabledMonitors.length > 1 ? "Drag a display to move it; click one to change it below." : "Click the display to change it below."
            textFormat: Text.PlainText
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            wrapMode: Text.Wrap
        }
    }

    // The display clicked on the map; its changes wait for Apply.
    Section {
        visible: root.current !== null
        title: root.current !== null ? root.current.name : ""

        FormCard {
            width: root.columnWidth

            // The last display in use cannot be switched off from here.
            FormRow {
                visible: root.selectedOff || root.enabledMonitors.length > 1
                label: "Use display"

                PillGroup {
                    current: !root.selectedOff
                    onPicked: on => root.reshape(root.current.name, {
                            disabled: !on
                        })
                }
            }

            FormRow {
                visible: !root.selectedOff
                label: "Resolution"

                ChoiceField {
                    choices: root.current !== null ? root.resolutions(root.current) : []
                    current: root.selectedState !== null ? root.selectedState.width + "x" + root.selectedState.height : ""
                    onPicked: value => root.pickResolution(value)
                }
            }

            FormRow {
                visible: !root.selectedOff
                label: "Refresh rate"

                ChoiceField {
                    id: rateField

                    readonly property var rates: root.current !== null ? root.rates(root.current) : []

                    choices: rateField.rates.map(rate => ({
                                label: root.rateText(rate) + " Hz",
                                value: rate
                            }))
                    current: rateField.rates.find(rate => Math.abs(root.selectedState?.rate - rate) < 0.01)
                    onPicked: rate => root.change(root.current.name, {
                            rate: rate
                        })
                }
            }

            FormRow {
                visible: !root.selectedOff
                label: "Scale"

                ChoiceField {
                    id: scaleField

                    readonly property var scales: root.current !== null ? root.scales(root.current) : []

                    choices: scaleField.scales.map(scale => ({
                                label: Math.round(scale * 100) + "%",
                                value: scale
                            }))
                    current: scaleField.scales.find(scale => Math.abs(root.selectedState?.scale - scale) < 0.001)
                    onPicked: scale => root.reshape(root.current.name, {
                            scale: scale
                        })
                }
            }

            FormRow {
                visible: !root.selectedOff
                label: "Rotation"

                PillGroup {
                    width: parent.width
                    choices: [
                        {
                            label: "Normal",
                            value: 0
                        },
                        {
                            label: "90°",
                            value: 1
                        },
                        {
                            label: "180°",
                            value: 2
                        },
                        {
                            label: "270°",
                            value: 3
                        }
                    ]
                    current: root.selectedState !== null ? root.selectedState.transform : -1
                    onPicked: transform => root.reshape(root.current.name, {
                            transform: transform
                        })
                }
            }

            FormRow {
                visible: !root.selectedOff
                label: "Adaptive sync"

                PillGroup {
                    width: parent.width
                    choices: [
                        {
                            label: "Off",
                            value: 0
                        },
                        {
                            label: "On",
                            value: 1
                        },
                        {
                            label: "Fullscreen only",
                            value: 2
                        }
                    ]
                    current: root.selectedState !== null ? root.selectedState.vrr : -1
                    onPicked: vrr => root.change(root.current.name, {
                            vrr: vrr
                        })
                }
            }

            Rectangle {
                width: parent.width
                height: Style.border.width
                color: Colors.base.border
            }

            // Apply and Discard; once applied, Keep and Revert with the seconds left.
            Item {
                width: parent.width
                height: Style.popup.itemHeight

                Text {
                    text: {
                        if (DisplayChange.waiting)
                            return "Keep current settings? Resetting in:" + DisplayChange.secondsLeft + " s";

                        if (DisplayChange.error !== "")
                            return DisplayChange.error;

                        if (root.hasPending)
                            return "Not applied yet";

                        return root.keptRule !== null ? "Settings saved" : "Set to default";
                    }
                    textFormat: Text.PlainText
                    color: DisplayChange.error !== "" && !DisplayChange.waiting ? Colors.status.error : Colors.text.muted
                    font.family: Style.text.font
                    font.pixelSize: Style.text.smallSize
                    elide: Text.ElideRight

                    anchors {
                        left: parent.left
                        right: buttons.left
                        rightMargin: Style.bar.spacing
                        verticalCenter: parent.verticalCenter
                    }
                }

                Row {
                    id: buttons

                    spacing: Style.bar.spacing

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }

                    PillButton {
                        visible: DisplayChange.waiting
                        text: "Revert"
                        onClicked: DisplayChange.revert()
                    }

                    PillButton {
                        visible: DisplayChange.waiting
                        text: "Keep"
                        action: true
                        onClicked: DisplayChange.keep()
                    }

                    PillButton {
                        visible: !DisplayChange.waiting && root.hasPending
                        text: "Discard"
                        onClicked: root.pending = {}
                    }

                    PillButton {
                        visible: !DisplayChange.waiting && root.hasPending
                        text: "Apply"
                        action: true
                        onClicked: root.applyPending()
                    }

                    PillButton {
                        visible: !DisplayChange.waiting && !root.hasPending && root.keptRule !== null
                        text: "Reset to config"
                        onClicked: DisplayChange.forget(root.keptRule.output)
                    }
                }
            }
        }
    }

    // Not monitor rules: these apply at once.
    Section {
        title: "ALL DISPLAYS"

        FormCard {
            width: root.columnWidth

            FormRow {
                visible: Quickshell.screens.length > 1
                label: "Main bar"

                PillGroup {
                    width: parent.width
                    choices: Quickshell.screens.map(screen => ({
                                label: screen.name,
                                value: screen.name
                            }))
                    current: BarLayout.main?.name ?? ""
                    onPicked: name => BarLayout.setMain(name)
                }
            }

            FormRow {
                visible: Quickshell.screens.length > 1
                label: "Small bars"

                PillGroup {
                    width: parent.width
                    choices: [
                        {
                            label: "Own space",
                            value: false
                        },
                        {
                            label: "Over windows",
                            value: true
                        }
                    ]
                    current: BarLayout.floating
                    onPicked: floating => BarLayout.setFloating(floating)
                }
            }

            FormRow {
                label: "Night light"

                PillGroup {
                    current: QuickToggles.nightLight
                    onPicked: on => QuickToggles.setNightLight(on)
                }
            }

            FormRow {
                label: "Warmth"

                Row {
                    width: parent.width
                    height: Style.popup.itemHeight
                    spacing: Style.widgets.spacing

                    // Left is warm: the slider runs from the coolest to the warmest.
                    PanelSlider {
                        width: parent.width - Style.settings.labelWidth - Style.widgets.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        value: (QuickToggles.nightLightCoolest - QuickToggles.nightLightTemperature) / (QuickToggles.nightLightCoolest - QuickToggles.nightLightWarmest)
                        onMoved: position => QuickToggles.setNightLightTemperature(Math.round((QuickToggles.nightLightCoolest - position * (QuickToggles.nightLightCoolest - QuickToggles.nightLightWarmest)) / 100) * 100)
                    }

                    Text {
                        width: Style.settings.labelWidth
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: QuickToggles.nightLightTemperature + " K"
                        textFormat: Text.PlainText
                        color: Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.smallSize
                    }
                }
            }
        }
    }

    // The quick settings' own page; the desktop has no backlight.
    Card {
        visible: Brightness.available
        width: root.columnWidth
        height: Math.floor(brightness.implicitHeight)

        BrightnessPanel {
            id: brightness

            anchors.fill: parent
            active: true
        }
    }
}
