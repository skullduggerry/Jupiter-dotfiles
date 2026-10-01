#!/usr/bin/env python3
"""Staging test for scripts/install-greeter.sh.

Runs the real script into a temporary destination (a staging install, so
/etc/pam.d is left alone) and checks that the tree greetd would run is
self-contained: the `greeter` user cannot read $HOME, so a symlink left in it --
etc/greetd/monitors.lua is one in the repo -- would dangle at boot and take the
greeter's compositor config down with it. Monitor rules the Settings app kept
are baked into the copy, applied after the config's own as in the session, and
so are the keyboard layouts it kept.

    python3 tests/install-greeter-test.py        exit 0 on success
"""
from __future__ import annotations

import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
SCRIPT = REPO / "scripts/install-greeter.sh"

failures: list[str] = []


def check(label: str, ok: bool, detail: str = "") -> None:
    print(f"  [{'ok  ' if ok else 'FAIL'}] {label}")
    if not ok:
        failures.append(f"{label}{': ' + detail if detail else ''}")


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        dest = tmp / "greetd"
        # The script takes the wallpaper from the saved hyprpaper config under
        # XDG_STATE_HOME, so the test brings its own instead of needing yours.
        state = tmp / "state"
        (state / "quickshell").mkdir(parents=True)
        wallpaper = tmp / "wallpaper.jpg"
        wallpaper.write_bytes(b"not really a jpeg")
        (state / "quickshell/hyprpaper.conf").write_text(
            f"wallpaper {{\n    monitor =\n    path = {wallpaper}\n}}\n")

        run = subprocess.run(["bash", str(SCRIPT), str(dest)], capture_output=True, text=True,
                             env=dict(os.environ, XDG_STATE_HOME=str(state)))
        check("script succeeds", run.returncode == 0, run.stderr.strip())
        if run.returncode != 0:
            return report()

        links = [str(p.relative_to(dest)) for p in dest.rglob("*") if p.is_symlink()]
        check("no symlinks in the installed tree", not links, ", ".join(links))

        monitors = dest / "monitors.lua"
        check("monitors.lua is the session's own layout",
              monitors.is_file() and monitors.read_bytes()
              == (REPO / ".config/hypr/modules/monitors.lua").read_bytes())

        config = (dest / "hyprland.lua").read_text()
        check("compositor config loads the monitors", 'require("monitors")' in config)
        check("staged paths point into the staging tree",
              f"{dest}/quickshell/shell.qml" in config and "/etc/greetd" not in config)

        for name in ("shell.qml", "qmldir", "greetd-auth.py", "style/qmldir",
                     "style/Colors.qml", "style/Style.qml", "style/Theme.qml"):
            check(f"quickshell/{name} installed", (dest / "quickshell" / name).is_file())
        check("wallpaper copied",
              (dest / "quickshell/wallpaper.jpg").read_bytes() == wallpaper.read_bytes())

        # Hyprland's own parser on the staged copy: proves `require` resolves
        # inside the staged tree rather than through the repo.
        if shutil.which("Hyprland"):
            verify = subprocess.run(["Hyprland", "--verify-config", "-c", str(dest / "hyprland.lua")],
                                    capture_output=True, text=True)
            output = (verify.stdout + verify.stderr).strip()
            check("staged compositor config verifies", "config ok" in output,
                  output.splitlines()[-1] if output else "")
        else:
            print("  [skip] Hyprland not installed, staged config not verified")

        # A second install with a monitor rule and keyboard layouts the
        # Settings app kept: appended to the copies, applied last, and still a
        # config Hyprland takes.
        kept = state / "quickshell/monitors.lua"
        kept.write_text('return {\n\t{ output = "desc:Test Monitor 1", mode = "1920x1080@60", '
                        'position = "0x0", scale = 1.25, transform = 0 },\n}\n')
        (state / "quickshell/keyboard.lua").write_text(
            '-- Written by the shell.\nreturn { kb_layout = "us,de", kb_variant = ",nodeadkeys" }\n')
        dest = tmp / "greetd-kept"
        run = subprocess.run(["bash", str(SCRIPT), str(dest)], capture_output=True, text=True,
                             env=dict(os.environ, XDG_STATE_HOME=str(state)))
        check("script succeeds with kept monitors", run.returncode == 0, run.stderr.strip())
        monitors = dest / "monitors.lua"
        text = monitors.read_bytes() if monitors.is_file() else b""
        own = (REPO / ".config/hypr/modules/monitors.lua").read_bytes()
        check("kept monitors come after the session's layout",
              text.startswith(own) and b"desc:Test Monitor 1" in text[len(own):])
        if shutil.which("lua"):
            stub = ('local last\nhl = { monitor = function(rule) last = rule.output end }\n'
                    f'dofile("{monitors}")\nprint(last)\n')
            order = subprocess.run(["lua", "-e", stub], capture_output=True, text=True,
                                   env={key: value for key, value in os.environ.items()
                                        if key not in ("HOME", "XDG_STATE_HOME")})
            check("the kept rule is applied last", order.stdout.strip() == "desc:Test Monitor 1",
                  (order.stdout + order.stderr).strip())
        if shutil.which("lua"):
            stub = ('local layouts\nhl = { monitor = function() end, on = function() end,\n'
                    '  config = function(values) if values.input then layouts = values.input.kb_layout end end }\n'
                    f'package.path = "{dest}/?.lua;" .. package.path\n'
                    f'dofile("{dest / "hyprland.lua"}")\nprint(layouts)\n')
            layouts = subprocess.run(["lua", "-e", stub], capture_output=True, text=True,
                                     env={key: value for key, value in os.environ.items()
                                          if key not in ("HOME", "XDG_STATE_HOME")})
            check("the greeter starts on the kept keyboard layouts", layouts.stdout.strip() == "us,de",
                  (layouts.stdout + layouts.stderr).strip())
        if shutil.which("Hyprland"):
            verify = subprocess.run(["Hyprland", "--verify-config", "-c", str(dest / "hyprland.lua")],
                                    capture_output=True, text=True)
            output = (verify.stdout + verify.stderr).strip()
            check("staged config with kept monitors and layouts verifies", "config ok" in output,
                  output.splitlines()[-1] if output else "")

        # A fresh install, before any wallpaper is on the disk: the greeter
        # goes without one rather than the install failing.
        wallpaper.unlink()
        dest = tmp / "greetd-fresh"
        run = subprocess.run(["bash", str(SCRIPT), str(dest)], capture_output=True, text=True,
                             env=dict(os.environ, XDG_STATE_HOME=str(state)))
        check("script succeeds without a wallpaper", run.returncode == 0, run.stderr.strip())
        check("no wallpaper installed", not (dest / "quickshell/wallpaper.jpg").exists())

    return report()


def report() -> int:
    print()
    if failures:
        print(f"FAILED ({len(failures)})")
        for failure in failures:
            print("  -", failure)
        return 1
    print("install-greeter: all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
