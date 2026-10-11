#!/usr/bin/env python3
"""Unit checks for the parts of nextcloud-calendar.py that decide *where* to look.

The calendar home used to be built from the login name, which breaks on any
account whose Nextcloud user id differs from what you type at the login box --
SSO-provisioned accounts (Authentik and friends) routinely have a UUID, and
Nextcloud accepts an email address as a login too. These cover the discovery
that replaced that assumption, and the transport guard that protects the app
password riding along as HTTP Basic auth.

    python3 tests/nextcloud-principal-test.py        exit 0 on success
"""

from __future__ import annotations

import importlib.util
import json
import pathlib
import subprocess
import sys
import xml.etree.ElementTree as ElementTree
from typing import Any

HELPER = (
    pathlib.Path(__file__).resolve().parent.parent
    / ".config/quickshell/services/nextcloud-calendar.py"
)
spec = importlib.util.spec_from_file_location("nextcloud_calendar", HELPER)
assert spec and spec.loader
helper: Any = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)


def multistatus(href: str | None) -> ElementTree.Element:
    inner = (
        f"<d:current-user-principal><d:href>{href}</d:href></d:current-user-principal>"
        if href
        else ""
    )
    return ElementTree.fromstring(
        '<?xml version="1.0"?>'
        '<d:multistatus xmlns:d="DAV:">'
        "<d:response><d:href>/remote.php/dav/</d:href>"
        f"<d:propstat><d:prop>{inner}</d:prop>"
        "<d:status>HTTP/1.1 200 OK</d:status></d:propstat>"
        "</d:response></d:multistatus>"
    )


failures: list[str] = []


def check(label: str, got: object, want: object) -> None:
    ok = got == want
    print(f"  [{'ok  ' if ok else 'FAIL'}] {label}")
    if not ok:
        failures.append(f"{label}: wanted {want!r}, got {got!r}")


# An Authentik-provisioned account: the id is a UUID, nothing like the login.
check(
    "uuid principal",
    helper.principal_id(
        multistatus(
            "/remote.php/dav/principals/users/6b3f1c02-9a77-4d51-bb0e-1f0e2f7d4c88/"
        )
    ),
    "6b3f1c02-9a77-4d51-bb0e-1f0e2f7d4c88",
)

# An id with a space stays percent-encoded, because it is pasted into a URL.
check(
    "encoded principal",
    helper.principal_id(
        multistatus("/remote.php/dav/principals/users/Jane%20Doe/")
    ),
    "Jane%20Doe",
)

check(
    "no trailing slash",
    helper.principal_id(multistatus("/remote.php/dav/principals/users/jane")),
    "jane",
)

# Missing property must fall back, not raise or return a stray path segment.
check("property absent", helper.principal_id(multistatus(None)), "")

check("https accepted", helper.is_secure("https://cloud.example.org"), True)
check(
    "plain http refused", helper.is_secure("http://cloud.example.org"), False
)
check("loopback http allowed", helper.is_secure("http://localhost:8080"), True)
check("loopback by address", helper.is_secure("http://127.0.0.1"), True)
check("no scheme refused", helper.is_secure("cloud.example.org"), False)

# The app password is the keyring's for one server, and asked for by it, so it
# never goes to another server that has a user of the same name.
asked: list[list[str]] = []


def keyring(
    command: list[str], **_: object
) -> subprocess.CompletedProcess[str]:
    asked.append(command)
    return subprocess.CompletedProcess(command, 0, "secret\n", "")


helper.subprocess.run = keyring
check(
    "keyring asked by server and user",
    (
        helper.keyring_password("https://cloud.example.org", "jane"),
        asked[-1][2:],
    ),
    (
        "secret",
        [
            "service",
            "nextcloud",
            "server",
            "https://cloud.example.org",
            "username",
            "jane",
        ],
    ),
)

# Signing in: the server's answers name the page for the browser and where the
# app password comes from, and both have to be https too.
LOGIN = (
    pathlib.Path(__file__).resolve().parent.parent
    / ".config/quickshell/services/nextcloud-login.py"
)
login_spec = importlib.util.spec_from_file_location("nextcloud_login", LOGIN)
assert login_spec and login_spec.loader
login: Any = importlib.util.module_from_spec(login_spec)
login_spec.loader.exec_module(login)


def sign_in_answer(base: str, answer: dict) -> str:
    login.post = lambda url, fields=None: (200, json.dumps(answer).encode())
    try:
        login.sign_in(base)
    except login.Failed as error:
        return str(error)
    return "accepted"


check(
    "plain http server refused before asking it",
    sign_in_answer("http://cloud.example.org", {}),
    "the server address must be https://",
)
check(
    "a plain http page for the browser refused",
    sign_in_answer(
        "https://cloud.example.org",
        {
            "login": "file:///etc/passwd",
            "poll": {
                "endpoint": "https://cloud.example.org/login/v2/poll",
                "token": "t",
            },
        },
    ),
    "the server answered with an address that is not https://",
)
check(
    "a plain http poll refused",
    sign_in_answer(
        "https://cloud.example.org",
        {
            "login": "https://cloud.example.org/login/v2/flow/x",
            "poll": {
                "endpoint": "http://cloud.example.org/login/v2/poll",
                "token": "t",
            },
        },
    ),
    "the server answered with an address that is not https://",
)

print()
if failures:
    print(f"FAILED ({len(failures)})")
    for failure in failures:
        print("  -", failure)
    sys.exit(1)
print("nextcloud-principal: all checks passed")
