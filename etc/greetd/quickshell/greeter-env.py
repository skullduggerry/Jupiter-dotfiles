#!/usr/bin/env python3
"""Who can log in, and into what, for the quickshell greeter.

    greeter-env.py

Prints one JSON object, read by GreeterService.qml through Quickshell.Io.Process:

    {"users": [{"name": "alice", "display": "Alice"}, ...],
     "sessions": [{"id": "hyprland-uwsm", "name": "Hyprland (uwsm-managed)",
                   "exec": "uwsm start -- hyprland.desktop",
                   "command": ["uwsm", "start", "--", "hyprland.desktop"]}, ...]}

The users are the login-capable accounts in world-readable /etc/passwd, the
sessions the desktop entries in the session directories, each with its Exec
split into the argv greetd's start_session takes. Logging in itself goes
through Quickshell.Services.Greetd.
"""

from __future__ import annotations

import json
import os
import shlex
import sys

PASSWD = "/etc/passwd"
SESSION_DIRS = ("/usr/share/wayland-sessions", "/usr/share/xsessions")

NOLOGIN_SHELLS = ("/usr/bin/nologin", "/sbin/nologin", "/usr/sbin/nologin",
                  "/bin/false", "/usr/bin/false")


def list_users(path: str = PASSWD) -> list[dict]:
    """Login-capable accounts: a regular user id and a shell to log in to."""
    users = []
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            fields = line.rstrip("\n").split(":")
            if len(fields) < 7:
                continue
            name, _, uid, _, gecos, _, shell = fields[:7]
            if not uid.isdigit() or not 1000 <= int(uid) < 65534:
                continue
            if shell in NOLOGIN_SHELLS:
                continue
            users.append({"name": name, "display": gecos.split(",")[0] or name})
    return sorted(users, key=lambda user: user["name"])


def desktop_entry(path: str) -> dict[str, str]:
    """The [Desktop Entry] group's keys, first occurrence winning."""
    keys, group = {}, None
    with open(path, encoding="utf-8", errors="replace") as handle:
        for line in handle:
            line = line.strip()
            if line.startswith("[") and line.endswith("]"):
                group = line[1:-1]
            elif group == "Desktop Entry" and "=" in line and not line.startswith("#"):
                key, value = line.split("=", 1)
                keys.setdefault(key.strip(), value.strip())
    return keys


def list_sessions(directories: tuple[str, ...] = SESSION_DIRS) -> list[dict]:
    """Desktop entries from the session directories, with their argv."""
    sessions = []
    for directory in directories:
        try:
            entries = sorted(os.listdir(directory))
        except OSError:
            continue
        for entry in entries:
            if not entry.endswith(".desktop"):
                continue
            keys = desktop_entry(os.path.join(directory, entry))
            name, exec_line = keys.get("Name", ""), keys.get("Exec", "")
            try:
                command = shlex.split(exec_line)
            except ValueError:
                continue
            if name and command:
                sessions.append({"id": entry[:-len(".desktop")], "name": name,
                                 "exec": exec_line, "command": command})
    return sessions


def main() -> int:
    json.dump({"users": list_users(), "sessions": list_sessions()}, sys.stdout)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
