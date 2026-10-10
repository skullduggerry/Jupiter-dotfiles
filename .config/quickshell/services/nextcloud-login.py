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

The app password is written straight to `secret-tool` on stdin, under the
server it belongs to (`service nextcloud server URL username NAME`, which
nextcloud-calendar.py looks up). It is never printed, never passed as an
argument and never handed back to QML -- the same rule the calendar fetcher
follows.

    services/nextcloud-login.py --url https://cloud.example.org
"""

from __future__ import annotations

import argparse
import http.client
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


class Failed(Exception):
    """Signing in cannot go on; the message says why."""


def emit(payload: dict) -> None:
    sys.stdout.write(json.dumps(payload) + "\n")
    sys.stdout.flush()


def is_secure(url: str) -> bool:
    """https anywhere, or plain http only when it cannot leave the machine,
    the same rule as nextcloud-calendar.py's."""
    parts = urllib.parse.urlsplit(url)
    if parts.scheme == "https":
        return True
    return parts.scheme == "http" and parts.hostname in ("localhost", "127.0.0.1", "::1")


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
        raise Failed(f"{url}: {error.reason}") from None
    except (OSError, http.client.HTTPException) as error:
        raise Failed(f"{url}: {error or type(error).__name__}") from None


def store(server: str, login_name: str, app_password: str) -> None:
    """Hand the secret to the keyring over stdin, never over argv."""
    try:
        result = subprocess.run(
            ["secret-tool", "store", "--label=Nextcloud",
             "service", "nextcloud", "server", server, "username", login_name],
            input=app_password,
            text=True,
            capture_output=True,
        )
    except FileNotFoundError:
        raise Failed("could not save to the keyring: secret-tool is not installed") from None
    if result.returncode != 0:
        detail = result.stderr.strip() or f"secret-tool exited {result.returncode}"
        raise Failed(f"could not save to the keyring: {detail}")


def sign_in(base: str) -> str:
    """The login name, once the browser has signed in and the app password
    is in the keyring."""
    if not is_secure(base):
        raise Failed("the server address must be https://")

    status, body = post(base + INIT_PATH)
    if status != 200:
        raise Failed(f"{base}{INIT_PATH}: HTTP {status}")
    try:
        started = json.loads(body)
        login = started["login"]
        poll_url = started["poll"]["endpoint"]
        token = started["poll"]["token"]
    except (ValueError, KeyError, TypeError):
        raise Failed("unexpected reply from login/v2") from None
    # Both come from the server: the page goes to the browser (xdg-open would
    # open any scheme it has a handler for), and the poll's answer carries the
    # app password, which a proxy that forgot it is behind https would send
    # back in the clear.
    if not (isinstance(login, str) and isinstance(poll_url, str) and is_secure(login) and is_secure(poll_url)):
        raise Failed("the server answered with an address that is not https://")
    emit({"status": "open", "url": login})

    deadline = time.monotonic() + GIVE_UP_SECONDS
    while time.monotonic() < deadline:
        time.sleep(POLL_SECONDS)
        try:
            status, body = post(poll_url, {"token": token})
        except Failed:
            continue  # a dropped poll is retried, as is an unfinished one
        if status == 404:
            continue  # nobody has finished signing in yet
        if status != 200:
            raise Failed(f"poll: HTTP {status}")
        try:
            finished = json.loads(body)
            login_name = finished["loginName"]
            app_password = finished["appPassword"]
        except (ValueError, KeyError, TypeError):
            raise Failed("unexpected reply while polling") from None
        store(base, login_name, app_password)
        return login_name

    raise Failed("timed out waiting for the browser sign-in")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", required=True, help="Nextcloud base address")
    arguments = parser.parse_args()

    base = arguments.url.rstrip("/")
    try:
        login_name = sign_in(base)
    except Failed as error:
        emit({"status": "error", "message": str(error)})
        return 1
    emit({"status": "ok", "server": base, "loginName": login_name})
    return 0


if __name__ == "__main__":
    sys.exit(main())
