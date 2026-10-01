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

    // Where a dragged monitor lands: against the side of the nearest other one
    // it was dropped towards, since Hyprland finds monitors in a direction
    // only across touching edges. Edges within a tenth snap into line; the
    // two always overlap along the shared edge. Null if it would cover a third.
    function landing(name, x, y) {
        const moving = root.footprint(root.effective(root.monitors.find(monitor => monitor.name === name)));
        const others = root.enabledMonitors.filter(monitor => monitor.name !== name).map(monitor => {
            const state = root.effective(monitor);
            const size = root.footprint(state);
            return {
                x: state.x,
                y: state.y,
                width: size.width,
                height: size.height
            };
        });
        if (others.length === 0)
            return {
                x: 0,
                y: 0
            };

        let nearest = others[0];
        let distance = Infinity;
        for (const other of others) {
            const gap = Math.hypot(x + moving.width / 2 - other.x - other.width / 2, y + moving.height / 2 - other.y - other.height / 2);
            if (gap < distance) {
                distance = gap;
                nearest = other;
            }
        }
        const align = (value, start, size, otherSize) => {
            const threshold = Math.max(size, otherSize) / 10;
            for (const candidate of [start, start + otherSize - size, start + (otherSize - size) / 2]) {
                if (Math.abs(value - candidate) < threshold)
                    return candidate;
            }
            return Math.max(start - size + 1, Math.min(start + otherSize - 1, value));
        };
        const dx = x + moving.width / 2 - nearest.x - nearest.width / 2;
        const dy = y + moving.height / 2 - nearest.y - nearest.height / 2;
        let landed;
        if (Math.abs(dx) / (moving.width + nearest.width) >= Math.abs(dy) / (moving.height + nearest.height))
            landed = {
                x: dx > 0 ? nearest.x + nearest.width : nearest.x - moving.width,
                y: align(y, nearest.y, moving.height, nearest.height)
            };
        else
            landed = {
                x: align(x, nearest.x, moving.width, nearest.width),
                y: dy > 0 ? nearest.y + nearest.height : nearest.y - moving.height
            };
        landed.x = Math.round(landed.x);
        landed.y = Math.round(landed.y);
        for (const other of others) {
            if (landed.x < other.x + other.width && landed.x + moving.width > other.x && landed.y < other.y + other.height && landed.y + moving.height > other.y)
                return null;
        }
        return landed;
    }

    // A drop moves one monitor; then the whole layout shifts to start at 0,0.
    function drop(name: string, dx: real, dy: real) {
        const state = root.effective(root.monitors.find(monitor => monitor.name === name));
        const landed = root.landing(name, state.x + dx, state.y + dy);
        if (landed === null)
            return;

        let left = Infinity;
        let top = Infinity;
        const places = {};
        for (const monitor of root.enabledMonitors) {
            const place = monitor.name === name ? landed : root.effective(monitor);
            places[monitor.name] = place;
            left = Math.min(left, place.x);
            top = Math.min(top, place.y);
        }
        for (const monitorName of Object.keys(places))
            root.change(monitorName, {
                x: places[monitorName].x - left,
                y: places[monitorName].y - top
            });
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
        root.change(root.current.name, {
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
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/quickshell/monitors.json"
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
                            color: Colors.text.base
                            font.family: Style.text.font
                            font.pixelSize: Style.text.size
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: tile.modelData.model || ""
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
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
            wrapMode: Text.Wrap
        }
    }

    Text {
        visible: root.current !== null
        width: root.columnWidth
        text: root.current !== null ? root.current.name + (root.current.description !== "" ? "  ·  " + root.current.description : "") : ""
        color: Colors.text.base
        font.family: Style.text.font
        font.pixelSize: Style.text.size
        font.weight: Font.Medium
        elide: Text.ElideRight
    }

    Section {
        visible: root.current !== null && !root.selectedState.disabled
        title: "RESOLUTION"
        // Above the sections after it, which its list opens over.
        z: 1

        ChoiceField {
            width: Style.settings.fieldWidth
            choices: root.current !== null ? root.resolutions(root.current) : []
            current: root.selectedState !== null ? root.selectedState.width + "x" + root.selectedState.height : ""
            onPicked: value => root.pickResolution(value)
        }
    }

    Section {
        visible: root.current !== null && !root.selectedState.disabled
        title: "REFRESH RATE"

        PillGroup {
            id: ratePills

            readonly property var rates: root.current !== null ? root.rates(root.current) : []

            width: root.columnWidth
            choices: ratePills.rates.map(rate => ({
                        label: root.rateText(rate) + " Hz",
                        value: rate
                    }))
            current: ratePills.rates.find(rate => Math.abs(root.selectedState.rate - rate) < 0.01)
            onPicked: rate => root.change(root.current.name, {
                    rate: rate
                })
        }
    }

    Section {
        visible: root.current !== null && !root.selectedState.disabled
        title: "SCALE"

        PillGroup {
            id: scalePills

            readonly property var scales: root.current !== null ? root.scales(root.current) : []

            width: root.columnWidth
            choices: scalePills.scales.map(scale => ({
                        label: Math.round(scale * 100) + "%",
                        value: scale
                    }))
            current: scalePills.scales.find(scale => Math.abs(root.selectedState.scale - scale) < 0.001)
            onPicked: scale => root.change(root.current.name, {
                    scale: scale
                })
        }
    }

    Section {
        visible: root.current !== null && !root.selectedState.disabled
        title: "ROTATION"

        PillGroup {
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
            onPicked: transform => root.change(root.current.name, {
                    transform: transform
                })
        }
    }

    Section {
        visible: root.current !== null && !root.selectedState.disabled
        title: "ADAPTIVE SYNC"

        PillGroup {
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

    Section {
        // The last display in use cannot be switched off from here.
        visible: root.current !== null && (root.selectedState.disabled || root.enabledMonitors.length > 1)
        title: "USE THIS DISPLAY"

        PillGroup {
            current: root.selectedState !== null && !root.selectedState.disabled
            onPicked: on => root.change(root.current.name, {
                    disabled: !on
                })
        }
    }

    // Apply and Discard; once applied, Keep and Revert with the seconds left.
    Item {
        visible: root.monitors.length > 0
        width: root.columnWidth
        height: Style.popup.itemHeight

        Text {
            text: {
                if (DisplayChange.waiting)
                    return "Keep these settings? Going back in " + DisplayChange.secondsLeft + " s";

                if (DisplayChange.error !== "")
                    return DisplayChange.error;

                if (root.hasPending)
                    return "Not applied yet";

                return root.keptRule !== null ? "Kept by Settings, applied at every login" : "As the Hyprland config sets it";
            }
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

    // Not monitor rules: these apply at once, like Night Light below.
    Section {
        visible: Quickshell.screens.length > 1
        title: "MAIN BAR"

        PillGroup {
            width: root.columnWidth
            choices: Quickshell.screens.map(screen => ({
                        label: screen.name,
                        value: screen.name
                    }))
            current: BarLayout.main?.name ?? ""
            onPicked: name => BarLayout.setMain(name)
        }
    }

    Section {
        visible: Quickshell.screens.length > 1
        title: "SMALL BARS"

        PillGroup {
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

    Section {
        title: "NIGHT LIGHT"

        PillGroup {
            current: QuickToggles.nightLight
            onPicked: on => QuickToggles.setNightLight(on)
        }

        Row {
            width: root.columnWidth
            spacing: Style.widgets.spacing

            Text {
                width: Style.settings.labelWidth
                anchors.verticalCenter: parent.verticalCenter
                text: "Warmth"
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
            }

            // Left is warm: the slider runs from the coolest to the warmest.
            PanelSlider {
                width: parent.width - Style.settings.labelWidth * 2 - Style.widgets.spacing * 2
                anchors.verticalCenter: parent.verticalCenter
                value: (QuickToggles.nightLightCoolest - QuickToggles.nightLightTemperature) / (QuickToggles.nightLightCoolest - QuickToggles.nightLightWarmest)
                onMoved: position => QuickToggles.setNightLightTemperature(Math.round((QuickToggles.nightLightCoolest - position * (QuickToggles.nightLightCoolest - QuickToggles.nightLightWarmest)) / 100) * 100)
            }

            Text {
                width: Style.settings.labelWidth
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                text: QuickToggles.nightLightTemperature + " K"
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
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
        }
    }
}
