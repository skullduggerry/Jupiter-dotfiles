#!/usr/bin/env python3
"""Fetch events from a Nextcloud calendar over CalDAV and print them as JSON.

Invoked by services/CalendarService.qml through Quickshell.Io.Process, which
is why the contract is "one JSON object on stdout, always":

    {"status": "ok", "events": [{...}, ...]}
    {"status": "unconfigured", "message": "..."}
    {"status": "error", "message": "..."}

The exit code is 0 for ok, 2 for unconfigured and 1 for anything else, so the
script is also usable on its own:

    services/nextcloud-calendar.py --start 2026-09-01 --end 2026-10-01 | jq

Configuration comes from the environment. The shell's calendar panel sets
NEXTCLOUD_URL and NEXTCLOUD_USER on this process; the password is never passed
in, and is read here from the keyring:

    NEXTCLOUD_URL           https://cloud.example.org
    NEXTCLOUD_USER          login name
    NEXTCLOUD_APP_PASSWORD  an app password; optional, see below

With no NEXTCLOUD_APP_PASSWORD the password is read from the session keyring
via secret-tool, so it never appears in a shell profile or a process list:

    secret-tool store --label='Nextcloud' service nextcloud username <user>

Use a Nextcloud *app password* (Settings -> Security -> Devices & sessions),
not the account password: it can be revoked on its own and skips 2FA.

The calendar home is discovered, not assumed: Nextcloud's is
/remote.php/dav/calendars/<user id>/, and the user id is not always what you log
in with. An account provisioned through SSO (Authentik and the like) often has a
UUID for an id, and Nextcloud accepts an email address at login too. One extra
PROPFIND for current-user-principal settles it.

Recurring events are expanded by the server (RFC 4791 <C:expand/>), so this
script never has to interpret an RRULE.

Standard library only: the `icalendar` and `caldav` packages are not
dependencies of this shell, and parsing what a time-range CalDAV query
returns needs very little of what they offer.
"""

from __future__ import annotations

import argparse
import base64
import concurrent.futures
import json
import os
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ElementTree
from datetime import date, datetime, time, timedelta, timezone
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

DAV = "DAV:"
CALDAV = "urn:ietf:params:xml:ns:caldav"
# Nextcloud stores a calendar's colour under Apple's namespace, which is what
# every CalDAV client reads it from; there is no DAV: or caldav: equivalent.
APPLE = "http://apple.com/ns/ical/"
NS = {"d": DAV, "c": CALDAV, "a": APPLE}

# The per-calendar REPORTs are independent, so overlapping them turns the wall
# time from the sum into roughly the slowest one. Kept low deliberately: at
# eight in flight this server started failing TLS handshakes outright, and a
# fetch that half-fails is worse than one that takes a second longer.
MAX_PARALLEL_CALENDARS = 4

TIMEOUT_SECONDS = 15
# Nextcloud's CalDAV collection layout is stable and documented, so only the
# principal is discovered; calendar-home-set would be a second extra request
# for a path this server always spells the same way.
DAV_ROOT = "/remote.php/dav/"
CALENDAR_HOME = "/remote.php/dav/calendars/{user}/"

PRINCIPAL_BODY = """<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:">
  <d:prop>
    <d:current-user-principal/>
  </d:prop>
</d:propfind>
"""

PROPFIND_BODY = """<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav"
            xmlns:a="http://apple.com/ns/ical/">
  <d:prop>
    <d:resourcetype/>
    <d:displayname/>
    <a:calendar-color/>
    <c:supported-calendar-component-set/>
  </d:prop>
</d:propfind>
"""

REPORT_BODY = """<?xml version="1.0" encoding="utf-8"?>
<c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
  <d:prop>
    <c:calendar-data>
      <c:expand start="{start}" end="{end}"/>
    </c:calendar-data>
  </d:prop>
  <c:filter>
    <c:comp-filter name="VCALENDAR">
      <c:comp-filter name="VEVENT">
        <c:time-range start="{start}" end="{end}"/>
      </c:comp-filter>
    </c:comp-filter>
  </c:filter>
</c:calendar-query>
"""


class Unconfigured(Exception):
    """Something required to reach the server is missing."""


class Failed(Exception):
    """The server was reachable but the request did not work out."""


# --------------------------------------------------------------------------
# configuration


def keyring_password(user: str) -> str:
    try:
        result = subprocess.run(
            ["secret-tool", "lookup", "service", "nextcloud", "username", user],
            capture_output=True,
            text=True,
            timeout=TIMEOUT_SECONDS,
        )
    except FileNotFoundError:
        raise Unconfigured(
            "NEXTCLOUD_APP_PASSWORD is not set and secret-tool is not installed"
        ) from None
    except subprocess.TimeoutExpired:
        raise Failed("secret-tool timed out; is the keyring unlocked?") from None

    if result.returncode != 0 or not result.stdout:
        raise Unconfigured(
            "no password: set NEXTCLOUD_APP_PASSWORD, or run "
            f"secret-tool store --label='Nextcloud' service nextcloud username {user}"
        )
    # secret-tool writes the secret verbatim; a trailing newline is the
    # storing tool's, not part of the password.
    return result.stdout.rstrip("\n")


def read_config() -> tuple[str, str, str]:
    url = os.environ.get("NEXTCLOUD_URL", "").strip().rstrip("/")
    user = os.environ.get("NEXTCLOUD_USER", "").strip()
    if not url:
        raise Unconfigured("NEXTCLOUD_URL is not set")
    if not user:
        raise Unconfigured("NEXTCLOUD_USER is not set")
    if not is_secure(url):
        # The app password goes out as HTTP Basic auth on every request.
        raise Unconfigured("NEXTCLOUD_URL must be https://")

    password = os.environ.get("NEXTCLOUD_APP_PASSWORD", "")
    if not password:
        password = keyring_password(user)
    return url, user, password


# --------------------------------------------------------------------------
# CalDAV


def is_secure(url: str) -> bool:
    """https anywhere, or plain http only when it cannot leave the machine."""
    parts = urllib.parse.urlsplit(url)
    if parts.scheme == "https":
        return True
    return parts.scheme == "http" and parts.hostname in ("localhost", "127.0.0.1", "::1")


def request(method: str, url: str, auth: str, body: str, depth: str) -> bytes:
    http_request = urllib.request.Request(
        url,
        method=method,
        data=body.encode(),
        headers={
            "Authorization": f"Basic {auth}",
            "Content-Type": 'application/xml; charset="utf-8"',
            "Depth": depth,
            "User-Agent": "quickshell-calendar/1",
        },
    )
    try:
        with urllib.request.urlopen(http_request, timeout=TIMEOUT_SECONDS) as response:
            return response.read()
    except urllib.error.HTTPError as error:
        hint = ""
        if error.code == 401:
            hint = " (wrong user or app password)"
        elif error.code == 404:
            hint = f" (no calendar home for this user at {url})"
        raise Failed(f"{method} {url}: HTTP {error.code} {error.reason}{hint}") from None
    except urllib.error.URLError as error:
        raise Failed(f"{method} {url}: {error.reason}") from None


def principal_id(document: ElementTree.Element) -> str:
    """The last path segment of current-user-principal, still URL-encoded.

    `<d:current-user-principal><d:href>/remote.php/dav/principals/users/a1b2/`
    means the account's id is `a1b2`, whatever name was used to log in.
    """
    href = document.findtext(".//d:current-user-principal/d:href", default="", namespaces=NS)
    return href.strip().rstrip("/").rsplit("/", 1)[-1] if href.strip() else ""


def calendar_home(base: str, user: str, auth: str) -> str:
    """Where this account's calendars live, asked rather than assumed."""
    document = ElementTree.fromstring(
        request("PROPFIND", base + DAV_ROOT, auth, PRINCIPAL_BODY, "0")
    )
    # hrefs come back percent-encoded, so an id taken from one is already safe
    # to paste into a URL; the login-name fallback is not.
    name = principal_id(document) or urllib.parse.quote(user)
    return base + CALENDAR_HOME.format(user=name)


def normalise_colour(value: str) -> str:
    """Reduce what a server stores to the #rrggbb QML can parse.

    Nextcloud writes #rrggbbaa; the alpha is dropped rather than honoured,
    since a calendar's own transparency is not something the agenda should
    inherit. Anything unrecognised becomes "" and the panel falls back to its
    own accent.
    """
    text = value.strip()
    if not text.startswith("#"):
        return ""
    digits = text[1:]
    if not all(character in "0123456789abcdefABCDEF" for character in digits):
        return ""
    if len(digits) in (3, 4):
        digits = "".join(character * 2 for character in digits[:3])
    elif len(digits) in (6, 8):
        digits = digits[:6]
    else:
        return ""
    return "#" + digits.lower()


def list_calendars(base: str, user: str, auth: str) -> list[tuple[str, str, str]]:
    """Return (href, display name, colour) for every VEVENT collection of `user`."""
    home = calendar_home(base, user, auth)
    document = ElementTree.fromstring(request("PROPFIND", home, auth, PROPFIND_BODY, "1"))

    calendars = []
    for response in document.findall("d:response", NS):
        href = response.findtext("d:href", default="", namespaces=NS)
        if not href or href.rstrip("/") == home_path(home).rstrip("/"):
            continue

        resourcetype = response.find(".//d:resourcetype", NS)
        if resourcetype is None or resourcetype.find("c:calendar", NS) is None:
            continue

        # Schedule inbox/outbox and subscriptions are calendar-shaped but
        # hold no events worth listing; a collection that doesn't advertise
        # VEVENT support (a contacts-only or VTODO-only list) is skipped too.
        components = {
            component.get("name")
            for component in response.findall(".//c:comp", NS)
        }
        if components and "VEVENT" not in components:
            continue

        name = response.findtext(".//d:displayname", default="", namespaces=NS)
        colour = response.findtext(".//a:calendar-color", default="", namespaces=NS)
        calendars.append(
            (href, name or href.rstrip("/").rsplit("/", 1)[-1], normalise_colour(colour))
        )
    return calendars


def home_path(home: str) -> str:
    """The path part of an absolute URL, which is what hrefs come back as."""
    return urllib.parse.urlsplit(home).path


def fetch_events(
    base: str,
    href: str,
    name: str,
    colour: str,
    auth: str,
    start: datetime,
    end: datetime,
) -> list[dict]:
    url = base + href if href.startswith("/") else href
    body = REPORT_BODY.format(start=as_caldav_utc(start), end=as_caldav_utc(end))
    document = ElementTree.fromstring(request("REPORT", url, auth, body, "1"))

    events = []
    for data in document.findall(".//c:calendar-data", NS):
        if not data.text:
            continue
        events.extend(parse_ics(data.text, name, colour))
    return events


def as_caldav_utc(moment: datetime) -> str:
    return moment.astimezone(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


# --------------------------------------------------------------------------
# iCalendar


def unfold(ics: str) -> list[str]:
    """Undo RFC 5545 line folding: a leading space or tab continues a line."""
    lines: list[str] = []
    for raw in ics.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        if raw[:1] in (" ", "\t") and lines:
            lines[-1] += raw[1:]
        else:
            lines.append(raw)
    return lines


def split_property(line: str) -> tuple[str, dict[str, str], str]:
    """Split "NAME;PARAM=value:content" into its three parts."""
    in_quotes = False
    for index, character in enumerate(line):
        if character == '"':
            in_quotes = not in_quotes
        elif character == ":" and not in_quotes:
            head, content = line[:index], line[index + 1:]
            break
    else:
        return "", {}, ""

    name, _, parameter_text = head.partition(";")
    parameters = {}
    if parameter_text:
        for parameter in split_parameters(parameter_text):
            key, _, value = parameter.partition("=")
            parameters[key.upper()] = value.strip('"')
    return name.upper(), parameters, content


def split_parameters(text: str) -> list[str]:
    parts: list[str] = [""]
    in_quotes = False
    for character in text:
        if character == '"':
            in_quotes = not in_quotes
            parts[-1] += character
        elif character == ";" and not in_quotes:
            parts.append("")
        else:
            parts[-1] += character
    return parts


def unescape_text(value: str) -> str:
    out = []
    escaped = False
    for character in value:
        if escaped:
            out.append({"n": "\n", "N": "\n"}.get(character, character))
            escaped = False
        elif character == "\\":
            escaped = True
        else:
            out.append(character)
    return "".join(out)


def parse_datetime(value: str, parameters: dict[str, str]) -> tuple[datetime, bool]:
    """Return (local datetime, is all-day) for a DTSTART/DTEND value."""
    if parameters.get("VALUE") == "DATE" or (len(value) == 8 and "T" not in value):
        return datetime.combine(date.fromisoformat(value), time()), True

    naive = datetime.strptime(value.rstrip("Z"), "%Y%m%dT%H%M%S")
    if value.endswith("Z"):
        moment = naive.replace(tzinfo=timezone.utc)
    elif "TZID" in parameters:
        try:
            moment = naive.replace(tzinfo=ZoneInfo(parameters["TZID"]))
        except (ZoneInfoNotFoundError, ValueError):
            # An unknown TZID is the server's problem, not a reason to drop
            # the event: treat it as floating local time and say nothing more
            # about it than the timestamp itself.
            return naive, False
    else:
        # A floating time means "whatever local time is", which it already is.
        return naive, False
    return moment.astimezone().replace(tzinfo=None), False


def parse_duration(value: str) -> timedelta:
    """Parse the RFC 5545 subset of ISO 8601 durations, e.g. -P1DT2H3M."""
    sign = -1 if value.startswith("-") else 1
    value = value.lstrip("+-").removeprefix("P")
    units = {"W": 0, "D": 0, "H": 0, "M": 0, "S": 0}
    number = ""
    for character in value:
        if character.isdigit():
            number += character
        elif character in units and number:
            units[character] = int(number)
            number = ""
        else:
            number = ""
    return sign * timedelta(
        weeks=units["W"],
        days=units["D"],
        hours=units["H"],
        minutes=units["M"],
        seconds=units["S"],
    )


def parse_ics(ics: str, calendar_name: str, colour: str = "") -> list[dict]:
    events = []
    current: dict | None = None

    for line in unfold(ics):
        name, parameters, content = split_property(line)
        if name == "BEGIN" and content == "VEVENT":
            current = {}
            continue
        if current is None:
            continue
        if name == "END" and content == "VEVENT":
            event = build_event(current, calendar_name, colour)
            if event:
                events.append(event)
            current = None
            continue
        if name in ("SUMMARY", "LOCATION", "STATUS"):
            current[name] = unescape_text(content)
        elif name in ("DTSTART", "DTEND", "DURATION"):
            current[name] = (content, parameters)

    return events


def build_event(fields: dict, calendar_name: str, colour: str = "") -> dict | None:
    if "DTSTART" not in fields:
        return None
    if fields.get("STATUS") == "CANCELLED":
        return None

    start, all_day = parse_datetime(*fields["DTSTART"])

    if "DTEND" in fields:
        end, _ = parse_datetime(*fields["DTEND"])
    elif "DURATION" in fields:
        end = start + parse_duration(fields["DURATION"][0])
    elif all_day:
        end = start + timedelta(days=1)
    else:
        end = start

    return {
        "summary": fields.get("SUMMARY", "(no title)"),
        "location": fields.get("LOCATION", ""),
        # Always a full local date-time, never a bare date: QML parses
        # "2026-09-12" as UTC midnight but "2026-09-12T00:00:00" as local,
        # which would shift all-day events by the UTC offset.
        "start": start.isoformat(timespec="seconds"),
        "end": end.isoformat(timespec="seconds"),
        "allDay": all_day,
        "calendar": calendar_name,
        # Empty when the server has no colour for the collection, which the
        # panel reads as "use the shell accent".
        "colour": colour,
    }


# --------------------------------------------------------------------------


def local_midnight(day: date) -> datetime:
    return datetime.combine(day, time()).astimezone()


def collect(start: date, end: date) -> tuple[list[dict], str]:
    """Return every event in the window, plus a note about any calendar lost."""
    base, user, password = read_config()
    auth = base64.b64encode(f"{user}:{password}".encode()).decode()

    calendars = list_calendars(base, user, auth)
    if not calendars:
        raise Failed(f"no calendars found for {user}")

    window_start = local_midnight(start)
    window_end = local_midnight(end)

    events: list[dict] = []
    failed: list[str] = []
    workers = min(MAX_PARALLEL_CALENDARS, len(calendars))
    # Each worker only reads shared state and urllib opens its own connection
    # per call, so there is nothing to guard here.
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {
            pool.submit(
                fetch_events, base, href, name, colour, auth, window_start, window_end
            ): name
            for href, name, colour in calendars
        }
        for future, name in futures.items():
            try:
                events.extend(future.result())
            except Failed:
                # One calendar timing out should cost its own events, not the
                # other eight; the next refresh picks it back up.
                failed.append(name)

    if len(failed) == len(calendars):
        raise Failed(f"no calendar could be read ({', '.join(failed)})")

    events.sort(key=lambda event: (event["start"], event["summary"]))
    return events, f"could not read {', '.join(failed)}" if failed else ""


def main() -> int:
    today = date.today()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--start",
        type=date.fromisoformat,
        default=today.replace(day=1),
        help="first day to fetch, YYYY-MM-DD (default: start of this month)",
    )
    parser.add_argument(
        "--end",
        type=date.fromisoformat,
        default=today.replace(day=1) + timedelta(days=62),
        help="day to fetch up to, exclusive (default: 62 days on)",
    )
    arguments = parser.parse_args()

    if arguments.end <= arguments.start:
        print(
            json.dumps({"status": "error", "message": "--end must be after --start"}),
            flush=True,
        )
        return 1

    try:
        events, warning = collect(arguments.start, arguments.end)
    except Unconfigured as error:
        print(json.dumps({"status": "unconfigured", "message": str(error)}), flush=True)
        return 2
    except Failed as error:
        print(json.dumps({"status": "error", "message": str(error)}), flush=True)
        return 1
    except ElementTree.ParseError as error:
        print(
            json.dumps(
                {"status": "error", "message": f"malformed CalDAV response: {error}"}
            ),
            flush=True,
        )
        return 1

    print(json.dumps({"status": "ok", "events": events, "message": warning}), flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
