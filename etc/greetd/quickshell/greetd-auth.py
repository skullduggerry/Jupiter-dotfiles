#!/usr/bin/env python3
"""Speak greetd's IPC protocol on behalf of the quickshell greeter.

Invoked by GreeterService.qml through Quickshell.Io.Process and kept running for
the life of the greeter, because greetd's wire format cannot be handled in QML:
greetd-ipc(7) frames every message as a 32-bit *native byte order* length
followed by UTF-8 JSON, and Quickshell.Io.Socket offers only write()/flush()
with text-delimiter parsers. So this script owns $GREETD_SOCK and exposes a
newline-delimited JSON protocol instead, which SplitParser can read.

Commands in, one JSON object per line on stdin:

    {"cmd": "login",    "username": "alice"}
    {"cmd": "password", "response": "..."}     answer to the last prompt
    {"cmd": "start",    "exec": "uwsm start -e -D Hyprland hyprland.desktop"}
    {"cmd": "cancel"}

Events out, one JSON object per line on stdout:

    {"type": "env", "users": [...], "sessions": [...]}   once, at startup
    {"type": "prompt",  "secret": true, "message": "Password:"}
    {"type": "info",    "message": "..."}    informative, needs an empty answer
    {"type": "authed"}                       credentials accepted
    {"type": "started"}                      greetd has the session; greeter may exit
    {"type": "error",   "kind": "auth_error", "message": "..."}
    {"type": "fatal",   "message": "..."}    socket gone; greeter cannot continue

The password arrives on stdin and is never placed in argv, which is world
readable through /proc. It is held only for the length of one response.

Standard library only, and no third-party greetd bindings: the protocol is two
struct calls wide and this runs before any user session exists.
"""

from __future__ import annotations

import collections
import json
import os
import selectors
import shlex
import socket
import struct
import sys

HEADER = struct.Struct("=I")

SESSION_DIRS = ("/usr/share/wayland-sessions", "/usr/share/xsessions")

NOLOGIN_SHELLS = ("/usr/bin/nologin", "/sbin/nologin", "/usr/sbin/nologin",
                  "/bin/false", "/usr/bin/false")


def emit(**event) -> None:
    """Write one event to QML. Line-delimited, flushed immediately."""
    sys.stdout.write(json.dumps(event) + "\n")
    sys.stdout.flush()


def send(sock: socket.socket, request: dict) -> None:
    payload = json.dumps(request).encode("utf-8")
    sock.sendall(HEADER.pack(len(payload)) + payload)


def recv_exactly(sock: socket.socket, count: int) -> bytes:
    chunks = []
    remaining = count
    while remaining:
        chunk = sock.recv(remaining)
        if not chunk:
            raise ConnectionError("greetd closed the connection")
        chunks.append(chunk)
        remaining -= len(chunk)
    return b"".join(chunks)


def receive(sock: socket.socket) -> dict:
    length, = HEADER.unpack(recv_exactly(sock, HEADER.size))
    return json.loads(recv_exactly(sock, length).decode("utf-8"))


def list_users() -> list[dict]:
    """Login-capable accounts, read from world-readable /etc/passwd."""
    users = []
    with open("/etc/passwd", encoding="utf-8") as handle:
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


def list_sessions() -> list[dict]:
    """Desktop entries from the session directories, as name/exec pairs."""
    sessions = []
    for directory in SESSION_DIRS:
        try:
            entries = sorted(os.listdir(directory))
        except OSError:
            continue
        for entry in entries:
            if not entry.endswith(".desktop"):
                continue
            name = exec_line = ""
            with open(os.path.join(directory, entry), encoding="utf-8") as handle:
                for line in handle:
                    line = line.rstrip("\n")
                    if line.startswith("Name=") and not name:
                        name = line[len("Name="):]
                    elif line.startswith("Exec=") and not exec_line:
                        exec_line = line[len("Exec="):]
            if name and exec_line:
                sessions.append({"name": name, "exec": exec_line,
                                 "id": entry[:-len(".desktop")]})
    return sessions


class LineReader:
    """Newline-delimited reads straight off a file descriptor.

    sys.stdin.readline() would read ahead into Python's own buffer, leaving
    select() with nothing to report while a command sits unread — a deadlock as
    soon as QML writes two commands in quick succession.
    """

    def __init__(self, fd: int) -> None:
        self.fd = fd
        self.buffer = b""

    def read_lines(self) -> list[str] | None:
        chunk = os.read(self.fd, 65536)
        if not chunk:
            return None
        self.buffer += chunk
        parts = self.buffer.split(b"\n")
        self.buffer = parts.pop()
        return [part.decode("utf-8") for part in parts if part.strip()]


class Greeter:
    """One outstanding request at a time; greetd answers strictly in order."""

    def __init__(self, sock: socket.socket) -> None:
        self.sock = sock
        self.pending = None
        self.queue = collections.deque()

    def submit(self, kind: str, **fields) -> None:
        self.queue.append((kind, fields))
        self.pump()

    def pump(self) -> None:
        if self.pending is not None or not self.queue:
            return
        kind, fields = self.queue.popleft()
        self.pending = kind
        send(self.sock, {"type": kind, **fields})

    def handle_command(self, command: dict) -> None:
        name = command.get("cmd")
        if name == "login":
            self.submit("create_session", username=command["username"])
        elif name == "password":
            self.submit("post_auth_message_response",
                        response=command.get("response", ""))
        elif name == "start":
            self.submit("start_session",
                        cmd=shlex.split(command["exec"]), env=[])
        elif name == "cancel":
            self.submit("cancel_session")
        else:
            emit(type="error", kind="protocol",
                 message=f"unknown command {name!r}")

    def handle_response(self, response: dict) -> None:
        kind = response.get("type")
        answered = self.pending
        self.pending = None

        if kind == "auth_message":
            message = response.get("auth_message", "")
            message_type = response.get("auth_message_type")
            if message_type in ("secret", "visible"):
                emit(type="prompt", secret=message_type == "secret",
                     message=message)
            else:
                emit(type="info", message=message)
                self.queue.appendleft(
                    ("post_auth_message_response", {"response": ""}))
        elif kind == "success":
            if answered == "start_session":
                emit(type="started")
            elif answered != "cancel_session":
                emit(type="authed")
        elif kind == "error":
            self.queue.clear()
            emit(type="error", kind=response.get("error_type", "error"),
                 message=response.get("description", ""))
        else:
            emit(type="error", kind="protocol",
                 message=f"unexpected response {kind!r}")

        self.pump()


def main() -> int:
    path = os.environ.get("GREETD_SOCK")
    if not path:
        emit(type="fatal", message="GREETD_SOCK is not set")
        return 1

    try:
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.connect(path)
    except OSError as error:
        emit(type="fatal", message=f"cannot connect to {path}: {error}")
        return 1

    emit(type="env", users=list_users(), sessions=list_sessions())

    greeter = Greeter(sock)
    commands = LineReader(sys.stdin.fileno())
    selector = selectors.DefaultSelector()
    selector.register(commands.fd, selectors.EVENT_READ, "stdin")
    selector.register(sock, selectors.EVENT_READ, "sock")

    with sock, selector:
        while True:
            for key, _ in selector.select():
                if key.data == "stdin":
                    lines = commands.read_lines()
                    if lines is None:
                        return 0
                    for line in lines:
                        try:
                            greeter.handle_command(json.loads(line))
                        except (ValueError, KeyError) as error:
                            emit(type="error", kind="protocol",
                                 message=str(error))
                else:
                    try:
                        greeter.handle_response(receive(sock))
                    except (ConnectionError, ValueError, struct.error) as error:
                        emit(type="fatal", message=str(error))
                        return 1


if __name__ == "__main__":
    sys.exit(main())
