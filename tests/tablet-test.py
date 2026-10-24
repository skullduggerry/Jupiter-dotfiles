#!/usr/bin/env python3
"""The drawing tablet: services/tablet.py and .config/hypr/modules/tablet.lua.

tablet.py has to find the tablet and its pad by udev's properties in a
stand-in /sys and udev database, with the tablet's size and the pad's
buttons (the digitizer's own codes left out), and read the pad's buttons as
press and release lines numbered in code order, ignoring everything else; a
FIFO cannot be grabbed, so it says "shared" first.

tablet.lua runs under plain Lua against a stand-in `hl`: from tablet.lua in
the state it maps every screen, the focused one or a named one, keeps the
tablet's used area to the shape of what it draws on (or the whole tablet
with keepRatio off), holds to a screen or a window and lets go on the second
press or when the window closes, and sends Hyprland nothing unchanged.

    python3 tests/tablet-test.py        exit 0 on success
"""

from __future__ import annotations

import json
import os
import pathlib
import select
import shutil
import struct
import subprocess
import sys
import tempfile
import time

REPO = pathlib.Path(__file__).resolve().parent.parent
HELPER = REPO / ".config/quickshell/services/tablet.py"
MODULE = REPO / ".config/hypr/modules/tablet.lua"
EVENT = struct.Struct("llHHi")

failures: list[str] = []


def check(label: str, got: object, want: object) -> None:
    ok = got == want
    print(f"  [{'ok  ' if ok else 'FAIL'}] {label}")
    if not ok:
        failures.append(f"{label}: wanted {want!r}, got {got!r}")


def device(
    root: pathlib.Path,
    event: str,
    number: str,
    name: str,
    props: dict[str, str],
    keys: str = "0",
) -> None:
    sysfs = root / "sys/class/input" / event
    (sysfs / "device/capabilities").mkdir(parents=True)
    (sysfs / "dev").write_text(f"13:{number}\n")
    (sysfs / "device/name").write_text(name + "\n")
    (sysfs / "device/capabilities/key").write_text(keys + "\n")
    udev = root / "run/udev/data"
    udev.mkdir(parents=True, exist_ok=True)
    lines = (
        ["I:123"]
        + [f"E:{key}={value}" for key, value in props.items()]
        + ["G:seat"]
    )
    (udev / f"c13:{number}").write_text("\n".join(lines) + "\n")


def describe(root: pathlib.Path) -> dict:
    result = subprocess.run(
        [sys.executable, str(HELPER)],
        env=dict(os.environ, TABLET_ROOT=str(root)),
        capture_output=True,
        text=True,
        check=False,
    )
    check("describe exits 0", result.returncode, 0)
    return json.loads(result.stdout)


def helper(root: pathlib.Path) -> None:
    print("tablet.py")
    check("no devices", describe(root), {"tablet": None, "pad": None})

    (root / "dev/input").mkdir(parents=True)
    # A keyboard first, which is neither.
    device(
        root,
        "event2",
        "66",
        "AT Keyboard",
        {"ID_INPUT": "1", "ID_INPUT_KEYBOARD": "1"},
    )
    device(
        root,
        "event21",
        "85",
        "Wacom Intuos BT M Pen",
        {
            "ID_INPUT": "1",
            "ID_INPUT_TABLET": "1",
            "ID_INPUT_WIDTH_MM": "216",
            "ID_INPUT_HEIGHT_MM": "135",
        },
        "1c01 0 0 0 0 0",
    )
    # BTN_0 to BTN_3, and BTN_STYLUS, which marks a pad as a tablet's.
    device(
        root,
        "event22",
        "86",
        "Wacom Intuos BT M Pad",
        {"ID_INPUT": "1", "ID_INPUT_TABLET": "1", "ID_INPUT_TABLET_PAD": "1"},
        "800 f 0 0 0 0",
    )
    node = root / "dev/input/event22"
    node.write_bytes(b"")
    node.chmod(0)
    check(
        "a tablet and an unreadable pad",
        describe(root),
        {
            "tablet": {
                "name": "Wacom Intuos BT M",
                "width": 216,
                "height": 135,
            },
            "pad": {"buttons": 4, "readable": os.geteuid() == 0},
        },
    )
    node.unlink()
    os.mkfifo(node)
    check(
        "a readable pad",
        describe(root)["pad"],
        {"buttons": 4, "readable": True},
    )

    reader = subprocess.Popen(
        [sys.executable, str(HELPER), "pad"],
        env=dict(os.environ, TABLET_ROOT=str(root)),
        stdout=subprocess.PIPE,
        bufsize=0,
    )
    assert reader.stdout is not None
    try:
        with open(node, "wb") as pad:
            events = [
                (3, 0, 1200),  # EV_ABS: not a button
                (1, 258, 1),  # BTN_2 down
                (1, 258, 2),  # an auto-repeat, which pads never mean
                (1, 331, 1),  # BTN_STYLUS: the digitizer's
                (1, 258, 0),  # BTN_2 up
                (1, 256, 1),  # BTN_0 down
                (0, 0, 0),  # EV_SYN
            ]
            pad.write(
                b"".join(
                    EVENT.pack(0, 0, kind, code, value)
                    for kind, code, value in events
                )
            )
        # Unbuffered: select() cannot see lines a buffered reader holds.
        output = b""
        deadline = time.monotonic() + 10
        while output.count(b"\n") < 6 and time.monotonic() < deadline:
            if select.select([reader.stdout], [], [], 0.5)[0]:
                output += os.read(reader.stdout.fileno(), 4096)
        lines = output.decode().splitlines()
        check(
            "pad lines",
            lines,
            [
                "shared",
                "connected 4",
                "press 2",
                "release 2",
                "press 0",
                "disconnected",
            ],
        )
    finally:
        reader.kill()
        reader.wait()

    check(
        "usage",
        subprocess.run(
            [sys.executable, str(HELPER), "what"],
            capture_output=True,
            check=False,
        ).returncode,
        1,
    )


# A stand-in for Hyprland's `hl`: two screens side by side, the left one
# focused, and a window on it. Every hl.config is printed as a line of JSON.
LUA = r"""
local function json(value)
	if type(value) == "table" then
		local parts = {}
		if #value > 0 then
			for _, item in ipairs(value) do parts[#parts + 1] = json(item) end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		local keys = {}
		for key in pairs(value) do keys[#keys + 1] = key end
		table.sort(keys)
		for _, key in ipairs(keys) do parts[#parts + 1] = string.format("%q:%s", key, json(value[key])) end
		return "{" .. table.concat(parts, ",") .. "}"
	elseif type(value) == "string" then
		return string.format("%q", value)
	end
	return tostring(value)
end

local left = { name = "DP-2", x = 0, y = 0, width = 1920, height = 1080, scale = 1 }
local right = { name = "eDP-1", x = 1920, y = 0, width = 2880, height = 1920, scale = 1.5 }
local window = { address = "0xabc", at = { x = 100, y = 50 }, size = { x = 800, y = 800 }, monitor = left, workspace = { active = true } }
local windows = { ["address:0xabc"] = window }
local timer = { on = false }
function timer:set_enabled(on) self.on = on end

hl = {
	timer = function(callback) timer.callback = callback return timer end,
	on = function() end,
	exec_cmd = function(command) print("exec " .. command) end,
	get_monitors = function() return { left, right } end,
	get_monitor = function(name) return name == left.name and left or name == right.name and right or nil end,
	get_active_monitor = function() return left end,
	get_active_window = function() return window end,
	get_window = function(selector) return windows[selector] end,
	config = function(config) print("config " .. json(config.input)) end,
}

local tablet = dofile(arg[1])
print("step use focused")
tablet.use({ area = "focused", keepRatio = true, width = 216, height = 135 })
print("step use focused again")
tablet.use({ area = "focused", keepRatio = true, width = 216, height = 135 })
print("step use eDP-1 stretched")
tablet.use({ area = "eDP-1", keepRatio = false, width = 216, height = 135, leftHanded = true, pressureMin = 0.1, pressureMax = 0.8 })
print("step use unplugged")
tablet.use({ area = "HDMI-A-1", width = 216, height = 135 })
print("step hold window")
tablet.holdWindow()
print("step timer " .. tostring(timer.on))
window.at = { x = 300, y = 50 }
timer.callback()
print("step hidden")
window.workspace = { active = false }
timer.callback()
print("step closed")
window.workspace = { active = true }
windows["address:0xabc"] = nil
timer.callback()
print("step timer " .. tostring(timer.on))
print("step hold screen")
tablet.holdScreen()
print("step release screen")
tablet.holdScreen()
"""


def module(root: pathlib.Path) -> None:
    print("tablet.lua")
    lua = shutil.which("lua5.4") or shutil.which("lua")
    assert lua is not None, "no lua"
    state = root / "state"
    (state / "quickshell").mkdir(parents=True)
    (state / "quickshell/tablet.lua").write_text(
        "return { area = 'all', width = 216, height = 135 }\n"
    )
    script = root / "hl.lua"
    script.write_text(LUA)
    result = subprocess.run(
        [lua, str(script), str(MODULE)],
        env=dict(os.environ, XDG_STATE_HOME=str(state)),
        capture_output=True,
        text=True,
        check=False,
    )
    check("lua exits 0", (result.returncode, result.stderr), (0, ""))
    steps: dict[str, list[str]] = {"load": []}
    current = "load"
    for line in result.stdout.splitlines():
        if line.startswith("step "):
            current = line[5:]
            steps[current] = []
        else:
            steps[current].append(line)

    def config(step: str) -> dict:
        lines = [line for line in steps[step] if line.startswith("config ")]
        check(f"{step}: one config", len(lines), 1)
        return json.loads(lines[0][7:]) if lines else {}

    # Every screen: 3840 x 1280 (the right one is 1920 x 1280 at scale 1.5),
    # so the tablet's full width and the middle 72 mm of its height.
    loaded = config("load")
    check(
        "load: every screen",
        (loaded["tablet"]["output"], loaded["tablet"]["region_size"]),
        ("", [0, 0]),
    )
    check("load: area", loaded["tablet"]["active_area_size"], [216, 72])
    check(
        "load: area position",
        loaded["tablet"]["active_area_position"],
        [0, 31.5],
    )
    check(
        "load: libinput's pressure",
        loaded["tablettool"],
        {"pressure_range_max": 1, "pressure_range_min": 0},
    )

    focused = config("use focused")
    check("focused: current", focused["tablet"]["output"], "current")
    check("focused: 16:9", focused["tablet"]["active_area_size"], [216, 121.5])
    check("unchanged: nothing sent", steps["use focused again"], [])

    stretched = config("use eDP-1 stretched")
    check("named screen", stretched["tablet"]["output"], "eDP-1")
    check(
        "stretched: whole tablet",
        stretched["tablet"]["active_area_size"],
        [216, 135],
    )
    check("left-handed", stretched["tablet"]["left_handed"], True)
    check(
        "pressure",
        stretched["tablettool"],
        {"pressure_range_max": 0.8, "pressure_range_min": 0.1},
    )

    unplugged = config("use unplugged")
    check(
        "unplugged screen: kept, every screen's shape",
        (
            unplugged["tablet"]["output"],
            unplugged["tablet"]["active_area_size"],
        ),
        ("HDMI-A-1", [216, 72]),
    )

    held = config("hold window")
    check(
        "window: its box on its screen",
        (
            held["tablet"]["output"],
            held["tablet"]["region_position"],
            held["tablet"]["region_size"],
        ),
        ("DP-2", [100, 50], [800, 800]),
    )
    check(
        "window: square",
        (
            held["tablet"]["active_area_position"],
            held["tablet"]["active_area_size"],
        ),
        ([40.5, 0], [135, 135]),
    )
    check(
        "window: said",
        any("Held to the window" in line for line in steps["hold window"]),
        True,
    )
    check(
        "window: followed",
        steps["timer true"][0].startswith("config ")
        and json.loads(steps["timer true"][0][7:])["tablet"][
            "region_position"
        ],
        [300, 50],
    )
    check(
        "hidden: where it would be unheld",
        config("hidden")["tablet"]["output"],
        "HDMI-A-1",
    )
    check(
        "closed: let go",
        any("Back on" in line for line in steps["closed"]),
        True,
    )
    check("closed: timer off", "timer false" in steps, True)

    screen = config("hold screen")
    check("screen: held", screen["tablet"]["output"], "DP-2")
    check(
        "screen: second press lets go",
        config("release screen")["tablet"]["output"],
        "HDMI-A-1",
    )


def main() -> int:
    with tempfile.TemporaryDirectory() as name:
        root = pathlib.Path(name)
        helper(root / "helper")
        module(root / "module")
    if failures:
        print("\n".join(["", "FAILED:", *failures]))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
