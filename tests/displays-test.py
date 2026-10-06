#!/usr/bin/env python3
"""The Settings app's monitor helper, and monitors.lua picking up what it kept.

`apply` has to hand hyprctl Lua that hl.monitor takes, `save` has to leave a
file that .config/hypr/modules/monitors.lua applies after its own rules (the
newest matching rule is the one Hyprland uses), and bad input must never reach
either. monitors.lua runs under plain lua with a stand-in `hl` that records
its calls; hyprctl is a stand-in on PATH that records what it was asked.
"""
import json
import os
import pathlib
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
HELPER = REPO / ".config" / "quickshell" / "settings" / "displays.py"
MONITORS = REPO / ".config" / "hypr" / "modules" / "monitors.lua"

failures = []


def check(condition, message):
    if not condition:
        failures.append(message)


RECORD = r"""
local calls = {}
hl = { monitor = function(rule) table.insert(calls, rule) end }
dofile(arg[1])
for _, rule in ipairs(calls) do
  local keys = {}
  for key in pairs(rule) do table.insert(keys, key) end
  table.sort(keys)
  local parts = {}
  for _, key in ipairs(keys) do table.insert(parts, key .. "=" .. tostring(rule[key])) end
  print(table.concat(parts, " "))
end
"""


def main():
    with tempfile.TemporaryDirectory() as tmp:
        root = pathlib.Path(tmp)
        bin_dir = root / "bin"
        bin_dir.mkdir()
        asked = root / "asked"
        hyprctl = bin_dir / "hyprctl"
        hyprctl.write_text(f"#!/bin/sh\nprintf '%s' \"$2\" > '{asked}'\necho ok\n")
        hyprctl.chmod(0o755)
        record = root / "record.lua"
        record.write_text(RECORD)
        env = dict(os.environ, XDG_STATE_HOME=str(root / "state"), HOME=str(root),
                   PATH=f"{bin_dir}:{os.environ.get('PATH', '')}")

        def run(*args, ok=True):
            result = subprocess.run([sys.executable, str(HELPER), *args], env=env, capture_output=True, text=True)
            check((result.returncode == 0) == ok, f"{args[0]}: exit {result.returncode} {result.stderr.strip()}")

        lg = {"output": 'desc:LG "27GL650F" 0x1', "mode": "1920x1080@143.98", "position": "0x0",
              "scale": 1.25, "transform": 0, "vrr": 1}
        run("apply", json.dumps([lg]))
        code = asked.read_text() if asked.exists() else ""
        check(code == 'hl.monitor({ output = "desc:LG \\"27GL650F\\" 0x1", mode = "1920x1080@143.98", '
                      'position = "0x0", scale = 1.25, transform = 0, vrr = 1 })', f"apply sent {code!r}")

        for bad in ('[{"mode": "1920x1080"}]', '[{"output": "DP-2", "nonsense": 1}]',
                    '[{"output": "DP-2", "scale": "big"}]', '[{"output": "DP-2", "vrr": true}]', "not json"):
            asked.unlink(missing_ok=True)
            run("apply", bad, ok=False)
            check(not asked.exists(), f"bad rules reached hyprctl: {bad}")

        run("save", json.dumps([lg]))
        run("save", json.dumps([{"output": "HDMI-A-1", "mode": "1920x1080@60", "position": "1920x0",
                                 "scale": 1, "transform": 1, "disabled": False}]))
        run("save", json.dumps([dict(lg, scale=1)]))
        kept = json.loads((root / "state" / "quickshell" / "monitors.json").read_text())
        check([rule["output"] for rule in kept] == [lg["output"], "HDMI-A-1"], f"kept {kept}")
        check(kept[0]["scale"] == 1, "a second save of an output did not replace the first")

        result = subprocess.run(["lua", str(record), str(MONITORS)], env=env, capture_output=True, text=True)
        check(result.returncode == 0, f"monitors.lua failed under lua: {result.stderr.strip()}")
        calls = result.stdout.splitlines()
        base = sum(1 for line in calls if 'desc:LG "27GL650F"' not in line and "transform=1" not in line)
        check(len(calls) == base + 2, f"monitors.lua made {calls}")
        check(calls[-2:] == ['mode=1920x1080@143.98 output=desc:LG "27GL650F" 0x1 position=0x0 scale=1 transform=0 vrr=1',
                             "disabled=false mode=1920x1080@60 output=HDMI-A-1 position=1920x0 scale=1 transform=1"],
              f"the kept rules did not come last: {calls[-2:]}")

        run("forget", "HDMI-A-1")
        kept = json.loads((root / "state" / "quickshell" / "monitors.json").read_text())
        check([rule["output"] for rule in kept] == [lg["output"]], f"forget left {kept}")

        # Nothing kept, or no HOME at all (the login screen's user): the
        # config's own rules and nothing else, and no error.
        for scene in (dict(env, XDG_STATE_HOME=str(root / "empty")),
                      {key: value for key, value in env.items() if key not in ("HOME", "XDG_STATE_HOME")}):
            result = subprocess.run(["lua", str(record), str(MONITORS)], env=scene, capture_output=True, text=True)
            check(result.returncode == 0 and len(result.stdout.splitlines()) == base,
                  f"without kept rules monitors.lua gave {result.returncode} {result.stdout!r} {result.stderr.strip()}")

    if failures:
        print("\n".join(failures))
        sys.exit(1)
    print("displays: ok")


if __name__ == "__main__":
    main()
