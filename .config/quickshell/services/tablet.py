#!/usr/bin/env python3
"""The drawing tablet and its pad, for services/Tablet.qml.

    tablet.py        print the tablet and its pad as JSON
    tablet.py pad    read the pad's buttons, one line each, until killed

The tablet is the first input device udev marks ID_INPUT_TABLET (and not
ID_INPUT_TABLET_PAD), with its size in mm, which udev works out from the
axes' resolution:

    {"tablet": {"name": "Wacom Intuos BT M", "width": 216, "height": 135},
     "pad": {"buttons": 4, "readable": true}}

either being null when there is none. Hyprland hands the pad's buttons to
the app under the pen and binds none of them, so `pad` reads them from the
device itself: it waits for a pad it may read (etc/udev/rules.d gives the
session's user that one device, nothing else), grabs it, so that the app
does not act on the same press, and prints

    connected 4        a pad with 4 buttons, numbered from 0
    press 2            a button went down
    release 2          and up
    shared             the grab failed: apps get the buttons too
    disconnected       the pad went away (a Bluetooth one does when idle)

Buttons are numbered in the order of their key codes, as libinput does.
TABLET_ROOT replaces / for the tests.
"""

import fcntl
import json
import os
import struct
import sys
import time
from pathlib import Path

ROOT = Path(os.environ.get("TABLET_ROOT", "/"))
INPUT = ROOT / "sys/class/input"
UDEV = ROOT / "run/udev/data"
DEV = ROOT / "dev/input"

EV_KEY = 1
# The digitizer's own codes (BTN_TOOL_PEN, BTN_STYLUS, …), which a pad
# carries only so that it is taken for part of a tablet.
DIGITIZER = range(0x140, 0x150)
EVIOCGRAB = 0x40044590
# struct input_event: a struct timeval, then type, code and value.
EVENT = struct.Struct("llHHi")
WAIT = 2.0  # seconds between looks for a pad while there is none


def properties(event: Path) -> dict[str, str]:
    """What udev knows about an input device, from its database."""
    try:
        major, minor = (event / "dev").read_text().strip().split(":")
        text = (UDEV / f"c{major}:{minor}").read_text()
    except (OSError, ValueError):
        return {}
    pairs = (
        line[2:].partition("=")
        for line in text.splitlines()
        if line.startswith("E:")
    )
    return {key: value for key, _, value in pairs}


def devices() -> list[tuple[Path, dict[str, str]]]:
    """Every event device, in the order of its number."""
    try:
        events = [
            path for path in INPUT.iterdir() if path.name.startswith("event")
        ]
    except OSError:
        return []
    events.sort(
        key=lambda path: int(path.name[5:]) if path.name[5:].isdigit() else 0
    )
    return [(event, properties(event)) for event in events]


def buttons(event: Path) -> list[int]:
    """The pad's button codes, from the bitmask sysfs prints: hex words of
    the machine's long, highest first."""
    words = (event / "device/capabilities/key").read_text().split()
    bits = struct.calcsize("l") * 8
    codes = []
    for index, word in enumerate(reversed(words)):
        value = int(word, 16)
        codes += [
            index * bits + bit for bit in range(bits) if value >> bit & 1
        ]
    return [code for code in codes if code >= 0x100 and code not in DIGITIZER]


def name(event: Path) -> str:
    """The device's name without its part: "Wacom Intuos BT M Pen" is the
    tablet "Wacom Intuos BT M"."""
    text = (event / "device/name").read_text().strip()
    for part in (" Pen", " Stylus", " Pad"):
        text = text.removesuffix(part)
    return text


def describe() -> dict:
    tablet = None
    pad = None
    for event, props in devices():
        if props.get("ID_INPUT_TABLET_PAD") == "1":
            if pad is None:
                pad = {
                    "buttons": len(buttons(event)),
                    "readable": os.access(DEV / event.name, os.R_OK),
                }
        elif props.get("ID_INPUT_TABLET") == "1" and tablet is None:
            tablet = {
                "name": name(event),
                "width": int(props.get("ID_INPUT_WIDTH_MM", "0") or 0),
                "height": int(props.get("ID_INPUT_HEIGHT_MM", "0") or 0),
            }
    return {"tablet": tablet, "pad": pad}


def find_pad() -> tuple[Path, list[int]] | None:
    for event, props in devices():
        node = DEV / event.name
        if props.get("ID_INPUT_TABLET_PAD") == "1" and os.access(
            node, os.R_OK
        ):
            return node, buttons(event)
    return None


def say(line: str) -> None:
    print(line, flush=True)


def read_pad(node: Path, codes: list[int]) -> None:
    """Prints the pad's buttons until it goes away; raises if it cannot be
    opened."""
    with open(node, "rb", buffering=0) as device:
        try:
            fcntl.ioctl(device, EVIOCGRAB, 1)
        except OSError:
            say("shared")
        say(f"connected {len(codes)}")
        while True:
            try:
                data = device.read(EVENT.size)
            except OSError:
                return
            if len(data) < EVENT.size:
                return
            _, _, kind, code, value = EVENT.unpack(data)
            # 2 is the kernel's auto-repeat, which pads do not send.
            if kind == EV_KEY and code in codes and value in (0, 1):
                say(f"{'press' if value else 'release'} {codes.index(code)}")


def pad() -> None:
    while True:
        found = find_pad()
        if found is not None:
            try:
                read_pad(*found)
                say("disconnected")
            except OSError:
                # Gone, or no longer ours, between the look and the open.
                pass
        time.sleep(WAIT)


def main() -> None:
    if sys.argv[1:] == ["pad"]:
        pad()
    elif sys.argv[1:] == []:
        say(json.dumps(describe()))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
