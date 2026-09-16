#!/usr/bin/env python3
"""Get a Nextcloud app password through Login Flow v2 and put it in the keyring.

The browser does the authenticating, which is the whole point. An account behind
an SSO provider has no password to type, and its Nextcloud user id is usually not
the name it signs in with -- authentik's own Nextcloud guide maps the user id
from `sub`, i.e. a UUID. Login Flow v2 hands back both the correct `loginName`
and a fresh app password, so neither has to be hunted down by hand.

Line-delimited JSON on stdout, for services/CalendarService.qml to read through
Quickshell.Io.Process:

    {"status": "open", "url": "https://.../login/v2/flow/..."}   first, always
    {"status": "ok", "server": "...", "loginName": "..."}        on success
    {"status": "error", "message": "..."}

The app password is written straight to `secret-tool` on stdin. It is never
printed, never passed as an argument and never handed back to QML -- the same
rule the calendar fetcher follows.

    services/nextcloud-login.py --url https://cloud.example.org
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

# Shown in Nextcloud under Settings -> Security -> Devices & sessions, so it can
# be recognised and revoked there.
DEVICE_NAME = "Quickshell calendar"
INIT_PATH = "/index.php/login/v2"
TIMEOUT_SECONDS = 15
POLL_SECONDS = 2
# The server keeps the token for 20 minutes; a shell process should not sit
# around that long, and signing in takes well under three.
GIVE_UP_SECONDS = 180


def emit(payload: dict) -> None:
    sys.stdout.write(json.dumps(payload) + "\n")
    sys.stdout.flush()


def post(url: str, fields: dict | None = None) -> tuple[int, bytes]:
    data = urllib.parse.urlencode(fields).encode() if fields else b""
    request = urllib.request.Request(
        url,
        method="POST",
        data=data,
        headers={"User-Agent": DEVICE_NAME},
    )
    try:
        with urllib.request.urlopen(request, timeout=TIMEOUT_SECONDS) as response:
            return response.status, response.read()
    except urllib.error.HTTPError as error:
        return error.code, error.read()
    except urllib.error.URLError as error:
        raise SystemExit(emit({"status": "error", "message": f"{url}: {error.reason}"}))


def store(login_name: str, app_password: str) -> None:
    """Hand the secret to the keyring over stdin, never over argv."""
    result = subprocess.run(
        ["secret-tool", "store", "--label=Nextcloud",
         "service", "nextcloud", "username", login_name],
        input=app_password,
        text=True,
        capture_output=True,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or f"secret-tool exited {result.returncode}"
        emit({"status": "error", "message": f"could not save to the keyring: {detail}"})
        raise SystemExit(1)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", required=True, help="Nextcloud base address")
    arguments = parser.parse_args()

    base = arguments.url.rstrip("/")
    status, body = post(base + INIT_PATH)
    if status != 200:
        emit({"status": "error", "message": f"{base}{INIT_PATH}: HTTP {status}"})
        return 1
    try:
        started = json.loads(body)
        poll_url = started["poll"]["endpoint"]
        token = started["poll"]["token"]
        emit({"status": "open", "url": started["login"]})
    except (ValueError, KeyError):
        emit({"status": "error", "message": "unexpected reply from login/v2"})
        return 1

    deadline = time.monotonic() + GIVE_UP_SECONDS
    while time.monotonic() < deadline:
        time.sleep(POLL_SECONDS)
        status, body = post(poll_url, {"token": token})
        if status == 404:
            continue  # nobody has finished signing in yet
        if status != 200:
            emit({"status": "error", "message": f"poll: HTTP {status}"})
            return 1
        try:
            finished = json.loads(body)
            login_name = finished["loginName"]
            store(login_name, finished["appPassword"])
        except (ValueError, KeyError):
            emit({"status": "error", "message": "unexpected reply while polling"})
            return 1
        emit({"status": "ok", "server": finished.get("server", base),
              "loginName": login_name})
        return 0

    emit({"status": "error", "message": "timed out waiting for the browser sign-in"})
    return 1


if __name__ == "__main__":
    sys.exit(main())
