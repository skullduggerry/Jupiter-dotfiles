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
import pathlib
import sys
import xml.etree.ElementTree as ElementTree

HELPER = (pathlib.Path(__file__).resolve().parent.parent
          / ".config/quickshell/services/nextcloud-calendar.py")
spec = importlib.util.spec_from_file_location("nextcloud_calendar", HELPER)
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)


def multistatus(href: str | None) -> ElementTree.Element:
    inner = f"<d:current-user-principal><d:href>{href}</d:href></d:current-user-principal>" if href else ""
    return ElementTree.fromstring(
        '<?xml version="1.0"?>'
        '<d:multistatus xmlns:d="DAV:">'
        "<d:response><d:href>/remote.php/dav/</d:href>"
        f"<d:propstat><d:prop>{inner}</d:prop>"
        "<d:status>HTTP/1.1 200 OK</d:status></d:propstat>"
        "</d:response></d:multistatus>"
    )


failures: list[str] = []


def check(label: str, got, want) -> None:
    ok = got == want
    print(f"  [{'ok  ' if ok else 'FAIL'}] {label}")
    if not ok:
        failures.append(f"{label}: wanted {want!r}, got {got!r}")


# An Authentik-provisioned account: the id is a UUID, nothing like the login.
check("uuid principal",
      helper.principal_id(multistatus(
          "/remote.php/dav/principals/users/6b3f1c02-9a77-4d51-bb0e-1f0e2f7d4c88/")),
      "6b3f1c02-9a77-4d51-bb0e-1f0e2f7d4c88")

# An id with a space stays percent-encoded, because it is pasted into a URL.
check("encoded principal",
      helper.principal_id(multistatus("/remote.php/dav/principals/users/Jane%20Doe/")),
      "Jane%20Doe")

check("no trailing slash",
      helper.principal_id(multistatus("/remote.php/dav/principals/users/jane")),
      "jane")

# Missing property must fall back, not raise or return a stray path segment.
check("property absent", helper.principal_id(multistatus(None)), "")

check("https accepted", helper.is_secure("https://cloud.example.org"), True)
check("plain http refused", helper.is_secure("http://cloud.example.org"), False)
check("loopback http allowed", helper.is_secure("http://localhost:8080"), True)
check("loopback by address", helper.is_secure("http://127.0.0.1"), True)
check("no scheme refused", helper.is_secure("cloud.example.org"), False)

print()
if failures:
    print(f"FAILED ({len(failures)})")
    for failure in failures:
        print("  -", failure)
    sys.exit(1)
print("nextcloud-principal: all checks passed")
