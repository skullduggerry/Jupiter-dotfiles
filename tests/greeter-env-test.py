#!/usr/bin/env python3
"""etc/greetd/quickshell/greeter-env.py: who the login screen offers, and the
sessions it can start, each with the argv greetd's start_session takes.

    python3 tests/greeter-env-test.py        exit 0 on success
"""
from __future__ import annotations

import importlib.util
import json
import pathlib
import subprocess
import sys
import tempfile

HELPER = (pathlib.Path(__file__).resolve().parent.parent
          / "etc/greetd/quickshell/greeter-env.py")
spec = importlib.util.spec_from_file_location("greeter_env", HELPER)
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)

failures: list[str] = []


def check(label: str, got, want) -> None:
    ok = got == want
    print(f"  [{'ok  ' if ok else 'FAIL'}] {label}")
    if not ok:
        failures.append(f"{label}: wanted {want!r}, got {got!r}")


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        passwd = tmp / "passwd"
        passwd.write_text("\n".join([
            "root:x:0:0::/root:/bin/bash",
            "greeter:x:959:959:greetd greeter user:/:/bin/bash",
            "nobody:x:65534:65534:Kernel Overflow User:/:/usr/bin/nologin",
            "zoe:x:1001:1001:Zoe Example,,,:/home/zoe:/bin/zsh",
            "alice:x:1000:1000::/home/alice:/bin/bash",
            "svc:x:1002:1002::/var/lib/svc:/usr/bin/nologin",
            "broken line",
        ]) + "\n")
        check("login-capable users, by name, with a display name",
              helper.list_users(str(passwd)),
              [{"name": "alice", "display": "alice"}, {"name": "zoe", "display": "Zoe Example"}])

        sessions = tmp / "wayland-sessions"
        sessions.mkdir()
        (sessions / "hyprland-uwsm.desktop").write_text(
            "[Desktop Entry]\nName=Hyprland (uwsm-managed)\n"
            'Exec=uwsm start -e -D Hyprland "hyprland.desktop"\n'
            "[Desktop Action Other]\nName=Not this\nExec=not-this\n")
        (sessions / "broken.desktop").write_text("[Desktop Entry]\nName=Broken\nExec=sh -c \"unbalanced\n")
        (sessions / "notes.txt").write_text("not a session\n")
        check("sessions with their argv, quotes and other groups handled",
              helper.list_sessions((str(sessions), str(tmp / "missing"))),
              [{"id": "hyprland-uwsm", "name": "Hyprland (uwsm-managed)",
                "exec": 'uwsm start -e -D Hyprland "hyprland.desktop"',
                "command": ["uwsm", "start", "-e", "-D", "Hyprland", "hyprland.desktop"]}])

    # This machine, as the greeter sees it.
    run = subprocess.run([sys.executable, str(HELPER)], capture_output=True, text=True, timeout=10)
    environment = json.loads(run.stdout)
    check("runs and lists someone to log in", bool(environment["users"]), True)
    check("a Hyprland session among them",
          any("Hyprland" in session["name"] for session in environment["sessions"]), True)

    print()
    if failures:
        print(f"FAILED ({len(failures)})")
        for failure in failures:
            print("  -", failure)
        return 1
    print("greeter-env: all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
