#!/usr/bin/env python3
"""Fetch events and open tasks from Nextcloud over CalDAV and print them as JSON.

Invoked by services/CalendarService.qml through Quickshell.Io.Process, which
is why the contract is "one JSON object on stdout, always":

    {"status": "ok", "events": [{...}, ...], "tasks": [{...}, ...]}
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
via secret-tool, so it never appears in a shell profile or a process list. It
is stored per server, so a password is never sent to another one that has a
user of the same name (the calendar's "Sign in" stores it this way):

    secret-tool store --label='Nextcloud' service nextcloud server <url> username <user>

Use a Nextcloud *app password* (Settings -> Security -> Devices & sessions),
not the account password: it can be revoked on its own and skips 2FA.

The calendar home is discovered, not assumed: Nextcloud's is
/remote.php/dav/calendars/<user id>/, and the user id is not always what you log
in with. An account provisioned through SSO (Authentik and the like) often has a
UUID for an id, and Nextcloud accepts an email address at login too. One extra
PROPFIND for current-user-principal settles it.

Recurring events are expanded by the server (RFC 4791 <C:expand/>), so this
script never has to interpret an RRULE.

Tasks are every VTODO not yet done, in any collection that holds them: the
Tasks app keeps its lists as VTODO-only calendars, and a calendar can hold
both. A task need not have a due date, so they are not fetched by time range;
the server leaves out the completed ones instead.

Standard library only: the `icalendar` and `caldav` packages are not
dependencies of this shell, and parsing what a time-range CalDAV query
returns needs very little of what they offer.
"""

from __future__ import annotations

import argparse
import base64
import concurrent.futures
import http.client
import json
import os
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ElementTree
from collections.abc import Callable
from datetime import date, datetime, time, timedelta, timezone
from typing import NamedTuple
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

EVENTS_BODY = """<?xml version="1.0" encoding="utf-8"?>
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

# A done task carries the time it was completed, so the server can leave every
# one of them out; they pile up, and nothing here shows them.
TASKS_BODY = """<?xml version="1.0" encoding="utf-8"?>
<c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
  <d:prop>
    <c:calendar-data/>
  </d:prop>
  <c:filter>
    <c:comp-filter name="VCALENDAR">
      <c:comp-filter name="VTODO">
        <c:prop-filter name="COMPLETED">
          <c:is-not-defined/>
        </c:prop-filter>
      </c:comp-filter>
    </c:comp-filter>
  </c:filter>
</c:calendar-query>
"""


class Calendar(NamedTuple):
    """A collection, and which of events and tasks it holds."""

    href: str
    name: str
    colour: str
    events: bool
    tasks: bool


class Unconfigured(Exception):
    """Something required to reach the server is missing."""


class Failed(Exception):
    """The server was reachable but the request did not work out."""


# --------------------------------------------------------------------------
# configuration


def keyring_password(url: str, user: str) -> str:
    try:
        result = subprocess.run(
            [
                "secret-tool",
                "lookup",
                "service",
                "nextcloud",
                "server",
                url,
                "username",
                user,
            ],
            capture_output=True,
            text=True,
            timeout=TIMEOUT_SECONDS,
            check=False,
        )
    except FileNotFoundError:
        raise Unconfigured(
            "NEXTCLOUD_APP_PASSWORD is not set and secret-tool is not installed"
        ) from None
    except subprocess.TimeoutExpired:
        raise Failed(
            "secret-tool timed out; is the keyring unlocked?"
        ) from None

    if result.returncode != 0 or not result.stdout:
        raise Unconfigured(
            f"no password for {user} on {url}: sign in with your browser, or run "
            f"secret-tool store --label='Nextcloud' service nextcloud server {url} username {user}"
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
        password = keyring_password(url, user)
    return url, user, password


# --------------------------------------------------------------------------
# CalDAV


def is_secure(url: str) -> bool:
    """https anywhere, or plain http only when it cannot leave the machine."""
    parts = urllib.parse.urlsplit(url)
    if parts.scheme == "https":
        return True
    return parts.scheme == "http" and parts.hostname in (
        "localhost",
        "127.0.0.1",
        "::1",
    )


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
        with urllib.request.urlopen(
            http_request, timeout=TIMEOUT_SECONDS
        ) as response:
            return response.read()
    except urllib.error.HTTPError as error:
        hint = ""
        if error.code == 401:
            hint = " (wrong user or app password)"
        elif error.code == 404:
            hint = f" (no calendar home for this user at {url})"
        raise Failed(
            f"{method} {url}: HTTP {error.code} {error.reason}{hint}"
        ) from None
    except urllib.error.URLError as error:
        raise Failed(f"{method} {url}: {error.reason}") from None
    # A timeout or a dropped connection while reading the answer, which urllib
    # passes on as it is rather than as a URLError.
    except (OSError, http.client.HTTPException) as error:
        raise Failed(
            f"{method} {url}: {error or type(error).__name__}"
        ) from None


def principal_id(document: ElementTree.Element) -> str:
    """The last path segment of current-user-principal, still URL-encoded.

    `<d:current-user-principal><d:href>/remote.php/dav/principals/users/a1b2/`
    means the account's id is `a1b2`, whatever name was used to log in.
    """
    href = document.findtext(
        ".//d:current-user-principal/d:href", default="", namespaces=NS
    )
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


def list_calendars(base: str, user: str, auth: str) -> list[Calendar]:
    """Every collection of `user` that holds events, tasks or both."""
    home = calendar_home(base, user, auth)
    document = ElementTree.fromstring(
        request("PROPFIND", home, auth, PROPFIND_BODY, "1")
    )

    calendars = []
    for response in document.findall("d:response", NS):
        href = response.findtext("d:href", default="", namespaces=NS)
        if not href or href.rstrip("/") == home_path(home).rstrip("/"):
            continue

        # Schedule inbox/outbox and subscriptions are not calendars here.
        resourcetype = response.find(".//d:resourcetype", NS)
        if resourcetype is None or resourcetype.find("c:calendar", NS) is None:
            continue

        # A collection says what it holds, and one that says nothing holds
        # anything (RFC 4791, 5.2.3). The Tasks app's lists are VTODO-only.
        components = {
            component.get("name")
            for component in response.findall(".//c:comp", NS)
        }
        events = not components or "VEVENT" in components
        tasks = not components or "VTODO" in components
        if not events and not tasks:
            continue

        name = response.findtext(".//d:displayname", default="", namespaces=NS)
        colour = response.findtext(
            ".//a:calendar-color", default="", namespaces=NS
        )
        calendars.append(
            Calendar(
                href,
                name or href.rstrip("/").rsplit("/", 1)[-1],
                normalise_colour(colour),
                events,
                tasks,
            )
        )
    return calendars


def home_path(home: str) -> str:
    """The path part of an absolute URL, which is what hrefs come back as."""
    return urllib.parse.urlsplit(home).path


def query(base: str, calendar: Calendar, auth: str, body: str) -> list[str]:
    """The iCalendar text of every object a calendar-query REPORT matches."""
    url = (
        base + calendar.href
        if calendar.href.startswith("/")
        else calendar.href
    )
    try:
        document = ElementTree.fromstring(
            request("REPORT", url, auth, body, "1")
        )
    except ElementTree.ParseError as error:
        raise Failed(
            f"REPORT {url}: malformed CalDAV response: {error}"
        ) from None
    return [
        data.text
        for data in document.findall(".//c:calendar-data", NS)
        if data.text
    ]


def fetch_events(
    base: str, calendar: Calendar, auth: str, start: datetime, end: datetime
) -> list[dict]:
    body = EVENTS_BODY.format(
        start=as_caldav_utc(start), end=as_caldav_utc(end)
    )
    return [
        event
        for ics in query(base, calendar, auth, body)
        for event in parse_ics(ics, calendar.name, calendar.colour)
    ]


def fetch_tasks(base: str, calendar: Calendar, auth: str) -> list[dict]:
    return [
        task
        for ics in query(base, calendar, auth, TASKS_BODY)
        for task in parse_tasks(ics, calendar.name, calendar.colour)
    ]


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
            head, content = line[:index], line[index + 1 :]
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


def parse_datetime(
    value: str, parameters: dict[str, str]
) -> tuple[datetime, bool]:
    """Return (local datetime, is all-day) for a DTSTART/DTEND value."""
    if parameters.get("VALUE") == "DATE" or (
        len(value) == 8 and "T" not in value
    ):
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


def components(
    ics: str, kind: str
) -> list[dict[str, tuple[str, dict[str, str]]]]:
    """The properties of every `kind` component (VEVENT, VTODO) in `ics`.

    What is nested inside one, a VALARM, is skipped: an alarm has a SUMMARY
    and a DURATION of its own, which must not stand in for its event's.
    """
    found = []
    current: dict | None = None
    depth = 0

    for line in unfold(ics):
        name, parameters, content = split_property(line)
        if current is None:
            if name == "BEGIN" and content == kind:
                current, depth = {}, 0
        elif name == "BEGIN":
            depth += 1
        elif name == "END" and depth > 0:
            depth -= 1
        elif name == "END":
            found.append(current)
            current = None
        elif depth == 0:
            current[name] = (content, parameters)

    return found


def text(fields: dict, name: str, default: str = "") -> str:
    return unescape_text(fields[name][0]) if name in fields else default


def built(
    build: Callable[[dict, str, str], dict | None],
    ics: str,
    kind: str,
    calendar_name: str,
    colour: str,
) -> list[dict]:
    """build() over every `kind` component, leaving out what it cannot read
    (a malformed date, say): one bad object costs only itself."""
    items = []
    for fields in components(ics, kind):
        try:
            item = build(fields, calendar_name, colour)
        except (ValueError, OverflowError):
            continue
        if item:
            items.append(item)
    return items


def parse_ics(ics: str, calendar_name: str, colour: str = "") -> list[dict]:
    return built(build_event, ics, "VEVENT", calendar_name, colour)


def parse_tasks(ics: str, calendar_name: str, colour: str = "") -> list[dict]:
    return built(build_task, ics, "VTODO", calendar_name, colour)


def build_event(
    fields: dict, calendar_name: str, colour: str = ""
) -> dict | None:
    if "DTSTART" not in fields:
        return None
    if text(fields, "STATUS") == "CANCELLED":
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
        "summary": text(fields, "SUMMARY", "(no title)"),
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


def build_task(
    fields: dict, calendar_name: str, colour: str = ""
) -> dict | None:
    # The server leaves out tasks with a completion time; a client that only
    # sets the status, and a cancelled task, are left out here.
    if text(fields, "STATUS") in ("COMPLETED", "CANCELLED"):
        return None
    # Unexpanded, a recurring task's changed instances come back beside it,
    # each another copy of the same task.
    if "RECURRENCE-ID" in fields:
        return None

    due, all_day = (
        parse_datetime(*fields["DUE"]) if "DUE" in fields else (None, False)
    )
    priority = text(fields, "PRIORITY")
    return {
        "summary": text(fields, "SUMMARY", "(no title)"),
        # Empty for a task with no due date, which Nextcloud allows; otherwise
        # a local date-time, as an event's start is.
        "due": due.isoformat(timespec="seconds") if due else "",
        "allDay": all_day,
        # 1 is the highest, 9 the lowest, 0 unset (RFC 5545, 3.8.1.9).
        "priority": int(priority) if priority.isdigit() else 0,
        "calendar": calendar_name,
        "colour": colour,
    }


def task_order(task: dict) -> tuple:
    """Due ones first, the soonest (the overdue) at the top, then the rest;
    within each, by priority, unset last."""
    return (
        task["due"] == "",
        task["due"],
        task["priority"] or 10,
        task["summary"].lower(),
    )


# --------------------------------------------------------------------------


def local_midnight(day: date) -> datetime:
    return datetime.combine(day, time()).astimezone()


def collect(start: date, end: date) -> tuple[list[dict], list[dict], str]:
    """Return every event in the window and every open task, plus a note
    about any calendar lost."""
    base, user, password = read_config()
    auth = base64.b64encode(f"{user}:{password}".encode()).decode()

    calendars = list_calendars(base, user, auth)
    if not calendars:
        raise Failed(f"no calendars found for {user}")

    window_start = local_midnight(start)
    window_end = local_midnight(end)

    events: list[dict] = []
    tasks: list[dict] = []
    failed: list[str] = []
    # Events and tasks are separate REPORTs, a calendar holding both costing
    # two, and all of them share the pool.
    jobs = [
        (
            fetch_events,
            (base, calendar, auth, window_start, window_end),
            events,
            calendar.name,
        )
        for calendar in calendars
        if calendar.events
    ] + [
        (fetch_tasks, (base, calendar, auth), tasks, calendar.name)
        for calendar in calendars
        if calendar.tasks
    ]
    # Each worker only reads shared state and urllib opens its own connection
    # per call, so there is nothing to guard here.
    with concurrent.futures.ThreadPoolExecutor(
        max_workers=min(MAX_PARALLEL_CALENDARS, len(jobs))
    ) as pool:
        futures = [
            (pool.submit(fetch, *arguments), into, name)
            for fetch, arguments, into, name in jobs
        ]
        lost = 0
        for future, into, name in futures:
            try:
                into.extend(future.result())
            except Failed:
                # One calendar timing out should cost its own events, not the
                # other eight; the next refresh picks it back up.
                lost += 1
                if name not in failed:
                    failed.append(name)

    if lost == len(jobs):
        raise Failed(f"no calendar could be read ({', '.join(failed)})")

    events.sort(key=lambda event: (event["start"], event["summary"]))
    tasks.sort(key=task_order)
    return (
        events,
        tasks,
        f"could not read {', '.join(failed)}" if failed else "",
    )


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
            json.dumps(
                {"status": "error", "message": "--end must be after --start"}
            ),
            flush=True,
        )
        return 1

    try:
        events, tasks, warning = collect(arguments.start, arguments.end)
    except Unconfigured as error:
        print(
            json.dumps({"status": "unconfigured", "message": str(error)}),
            flush=True,
        )
        return 2
    except Failed as error:
        print(
            json.dumps({"status": "error", "message": str(error)}), flush=True
        )
        return 1
    except ElementTree.ParseError as error:
        print(
            json.dumps(
                {
                    "status": "error",
                    "message": f"malformed CalDAV response: {error}",
                }
            ),
            flush=True,
        )
        return 1

    print(
        json.dumps(
            {
                "status": "ok",
                "events": events,
                "tasks": tasks,
                "message": warning,
            }
        ),
        flush=True,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
