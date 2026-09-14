#!/usr/bin/env python3
"""Protocol test for etc/greetd/quickshell/greetd-auth.py.

Stands up a stub greetd speaking the real greetd-ipc(7) wire format -- a 32-bit
native-order length prefix followed by UTF-8 JSON -- so the helper's framing is
exercised for real rather than mocked. Covers the branches that actually broke
during development: startup enumeration, the password prompt, a rejected
password, cancel-and-retry ordering, and the session hand-off.

    python3 tests/greetd-auth-test.py        exit 0 on success
"""
from __future__ import annotations

import json, os, pathlib, socket, struct, subprocess, sys, tempfile, threading, time

HEADER = struct.Struct("=I")
PASSWORD = "correct-horse"
HELPER = str(pathlib.Path(__file__).resolve().parent.parent
             / "etc/greetd/quickshell/greetd-auth.py")


def send(sock, obj):
    payload = json.dumps(obj).encode()
    sock.sendall(HEADER.pack(len(payload)) + payload)


def recv(sock):
    head = b""
    while len(head) < HEADER.size:
        chunk = sock.recv(HEADER.size - len(head))
        if not chunk:
            return None
        head += chunk
    length, = HEADER.unpack(head)
    body = b""
    while len(body) < length:
        chunk = sock.recv(length - len(body))
        if not chunk:
            return None
        body += chunk
    return json.loads(body.decode())


def serve(path, seen):
    """One connection, the full greetd state machine, recording requests."""
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(path)
    server.listen(1)
    conn, _ = server.accept()
    with conn:
        while True:
            request = recv(conn)
            if request is None:
                break
            seen.append(request["type"])
            kind = request.get("type")
            if kind == "create_session":
                send(conn, {"type": "auth_message",
                            "auth_message_type": "secret",
                            "auth_message": "Password:"})
            elif kind == "post_auth_message_response":
                if request.get("response") == PASSWORD:
                    send(conn, {"type": "success"})
                else:
                    send(conn, {"type": "error",
                                "error_type": "auth_error",
                                "description": "authentication failed"})
            elif kind in ("start_session", "cancel_session"):
                send(conn, {"type": "success"})
            else:
                send(conn, {"type": "error", "error_type": "error",
                            "description": f"unknown {kind}"})
    server.close()
    os.unlink(path)


def main() -> int:
    tmp = tempfile.mkdtemp()
    path = os.path.join(tmp, "greetd.sock")
    seen: list[str] = []
    threading.Thread(target=serve, args=(path, seen), daemon=True).start()
    time.sleep(0.3)

    proc = subprocess.Popen(["python3", HELPER], text=True,
                            env=dict(os.environ, GREETD_SOCK=path),
                            stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)

    def read():
        line = proc.stdout.readline()
        assert line, f"helper exited: {proc.stderr.read()}"
        return json.loads(line)

    def say(**cmd):
        proc.stdin.write(json.dumps(cmd) + "\n")
        proc.stdin.flush()

    failures = []

    def check(label, got, want):
        ok = all(got.get(k) == v for k, v in want.items())
        print(f"  [{'ok  ' if ok else 'FAIL'}] {label}")
        if not ok:
            failures.append(f"{label}: wanted {want}, got {got}")

    environment = read()
    check("startup enumeration", environment, {"type": "env"})
    users = [u["name"] for u in environment.get("users", [])]
    sessions = [s["name"] for s in environment.get("sessions", [])]
    if not users:
        failures.append("no login-capable users enumerated")
    if not any("Hyprland" in s for s in sessions):
        failures.append(f"no Hyprland session enumerated: {sessions}")
    print(f"         users={users} sessions={sessions}")

    say(cmd="login", username=users[0] if users else "root")
    check("password prompt", read(), {"type": "prompt", "secret": True})

    say(cmd="password", response="not-the-password")
    check("wrong password rejected", read(), {"type": "error", "kind": "auth_error"})

    say(cmd="cancel")
    say(cmd="login", username=users[0] if users else "root")
    check("prompt again after cancel", read(), {"type": "prompt", "secret": True})

    say(cmd="password", response=PASSWORD)
    check("correct password accepted", read(), {"type": "authed"})

    say(cmd="start", exec="uwsm start -e -D Hyprland hyprland.desktop")
    check("session started", read(), {"type": "started"})

    proc.stdin.close()
    proc.wait(timeout=5)

    # greetd is strictly request/response: a cancel must reach it before the
    # retry, or the retry is answered against a session that is still open.
    expected = ["create_session", "post_auth_message_response", "cancel_session",
                "create_session", "post_auth_message_response", "start_session"]
    if seen != expected:
        failures.append(f"request order was {seen}, expected {expected}")
    else:
        print("  [ok  ] request ordering")

    print()
    if failures:
        print(f"FAILED ({len(failures)})")
        for f in failures:
            print("  -", f)
        return 1
    print("greetd-auth: all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
