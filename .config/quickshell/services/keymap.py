#!/usr/bin/env python3
"""The keys of Hyprland's keyboard layouts, for the shortcuts overlay.

    keymap.py LAYOUTS VARIANTS

LAYOUTS and VARIANTS are input:kb_layout and kb_variant as the keyboard has
them ("us,de" and ","). The rules, model and options are Hyprland's, so the
keymap is the one it compiles (xkbcommon, through ctypes). Prints each key by
its XKB name with its keycode and, per layout, the keysyms and text of its
first two levels (as typed, and with Shift), and whether binds go by the
layout in use (input:resolve_binds_by_sym) rather than by the first:

    {"resolveBySym": false, "layouts": [{"iso": false, "keys": {"AD01":
    {"code": 24, "syms": ["q", "Q"], "text": ["q", "Q"]}, ...}}, ...]}

A layout is drawn ISO when the key between left Shift and Z (LSGT) types a
character no other key does: "<" on de, which an ANSI keyboard could not type,
but not on us, whose "<" is Shift and comma.
"""

import ctypes
import json
import os
import subprocess
import sys

# What a dead key's cap shows: the accent it puts on the next letter.
DEAD = {
    "grave": "`",
    "acute": "´",
    "circumflex": "^",
    "tilde": "~",
    "macron": "¯",
    "breve": "˘",
    "abovedot": "˙",
    "diaeresis": "¨",
    "abovering": "˚",
    "doubleacute": "˝",
    "caron": "ˇ",
    "cedilla": "¸",
    "ogonek": "˛",
}


class RuleNames(ctypes.Structure):
    _fields_ = [
        (field, ctypes.c_char_p)
        for field in ("rules", "model", "layout", "variant", "options")
    ]


def hyprland_option(name):
    """An input option's value as Hyprland has it, None where it cannot say."""
    try:
        reply = subprocess.run(
            ["hyprctl", "-j", "getoption", "input:" + name],
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        ).stdout
        option = json.loads(reply)
    except (OSError, ValueError, subprocess.SubprocessError):
        return None
    for kind in ("str", "bool", "int"):
        if kind in option:
            return "" if option[kind] == "[[EMPTY]]" else option[kind]
    return None


def loaded(name, maps):
    """The path of the library `name` (any version of it) in a process's
    memory map."""
    try:
        with open(maps, encoding="utf-8", errors="replace") as file:
            for line in file:
                fields = line.rstrip("\n").split(maxsplit=5)
                if len(fields) == 6 and os.path.basename(fields[5]).startswith(
                    name
                ):
                    return fields[5]
    except OSError:
        pass
    raise SystemExit(f"keymap: {name} not found")


def library():
    name = "libxkbcommon.so.0"
    try:
        xkb = ctypes.CDLL(name)
    except OSError:
        # NixOS puts no library where the loader looks by name. The shell
        # that runs this has it loaded (Qt links it): that one, by its path.
        xkb = ctypes.CDLL(loaded(name, f"/proc/{os.getppid()}/maps"))
    pointer = ctypes.c_void_p
    signatures = {
        "xkb_context_new": ([ctypes.c_int], pointer),
        "xkb_keymap_new_from_names": (
            [pointer, ctypes.POINTER(RuleNames), ctypes.c_int],
            pointer,
        ),
        "xkb_keymap_num_layouts": ([pointer], ctypes.c_uint32),
        "xkb_keymap_min_keycode": ([pointer], ctypes.c_uint32),
        "xkb_keymap_max_keycode": ([pointer], ctypes.c_uint32),
        "xkb_keymap_key_get_name": (
            [pointer, ctypes.c_uint32],
            ctypes.c_char_p,
        ),
        "xkb_keymap_key_get_syms_by_level": (
            [
                pointer,
                ctypes.c_uint32,
                ctypes.c_uint32,
                ctypes.c_uint32,
                ctypes.POINTER(ctypes.POINTER(ctypes.c_uint32)),
            ],
            ctypes.c_int,
        ),
        "xkb_keysym_get_name": (
            [ctypes.c_uint32, ctypes.c_char_p, ctypes.c_size_t],
            ctypes.c_int,
        ),
        "xkb_keysym_to_utf8": (
            [ctypes.c_uint32, ctypes.c_char_p, ctypes.c_size_t],
            ctypes.c_int,
        ),
    }
    for name, (arguments, result) in signatures.items():
        function = getattr(xkb, name)
        function.argtypes = arguments
        function.restype = result
    return xkb


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    try:
        xkb = library()
    except OSError as error:
        raise SystemExit(f"keymap: no xkbcommon: {error}") from None

    options = {
        name: hyprland_option(name)
        for name in (
            "kb_rules",
            "kb_model",
            "kb_options",
            "resolve_binds_by_sym",
        )
    }
    if None in options.values():
        print(
            "keymap: hyprctl did not answer, so xkbcommon's own rules, model and options",
            file=sys.stderr,
        )

    def option(name):
        return (options[name] or "").encode()

    names = RuleNames(
        option("kb_rules"),
        option("kb_model"),
        sys.argv[1].encode(),
        sys.argv[2].encode(),
        option("kb_options"),
    )
    keymap = xkb.xkb_keymap_new_from_names(
        xkb.xkb_context_new(0), ctypes.byref(names), 0
    )
    if not keymap:
        raise SystemExit(
            f"keymap: xkbcommon could not compile {sys.argv[1]!r} ({sys.argv[2]!r})"
        )

    buffer = ctypes.create_string_buffer(64)

    def level(code, layout, index):
        symbols = ctypes.POINTER(ctypes.c_uint32)()
        if (
            xkb.xkb_keymap_key_get_syms_by_level(
                keymap, code, layout, index, ctypes.byref(symbols)
            )
            < 1
        ):
            return "", ""
        xkb.xkb_keysym_get_name(symbols[0], buffer, len(buffer))
        name = buffer.value.decode()
        length = xkb.xkb_keysym_to_utf8(symbols[0], buffer, len(buffer))
        text = buffer.value.decode() if length > 0 else ""
        if name.startswith("dead_"):
            text = DEAD.get(name[len("dead_") :], "")
        # Return, Tab, Escape and the like come out as control characters.
        return name, text if text.isprintable() and not text.isspace() else ""

    layouts = []
    for layout in range(xkb.xkb_keymap_num_layouts(keymap)):
        keys: dict[str, dict] = {}
        for code in range(
            xkb.xkb_keymap_min_keycode(keymap),
            xkb.xkb_keymap_max_keycode(keymap) + 1,
        ):
            name = xkb.xkb_keymap_key_get_name(keymap, code)
            levels = [level(code, layout, index) for index in (0, 1)]
            if name and levels[0][0]:
                keys[name.decode()] = {
                    "code": code,
                    "syms": [sym for sym, _ in levels],
                    "text": [text for _, text in levels],
                }
        less = keys.get("LSGT", {}).get("text", [""])[0]
        elsewhere = {
            text
            for name, key in keys.items()
            if name != "LSGT"
            for text in key["text"]
        }
        layouts.append(
            {"iso": less != "" and less not in elsewhere, "keys": keys}
        )

    print(
        json.dumps(
            {
                "resolveBySym": bool(options["resolve_binds_by_sym"]),
                "layouts": layouts,
            }
        )
    )


if __name__ == "__main__":
    main()
