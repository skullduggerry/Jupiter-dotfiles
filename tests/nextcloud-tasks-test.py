#!/usr/bin/env python3
"""Tasks in nextcloud-calendar.py: which collections hold them, which of them
are open, and the order the calendar dropdown lists them in.

The helper runs end to end against a stand-in CalDAV server on loopback (the
one place it accepts plain http), which answers the way Nextcloud does: a
principal, a calendar home listing each collection's components, and REPORTs
that honour the COMPLETED filter. Its timezone is UTC, so due times read back
exactly as written.

    python3 tests/nextcloud-tasks-test.py        exit 0 on success
"""

from __future__ import annotations

import http.server
import importlib.util
import json
import os
import pathlib
import subprocess
import sys
import threading
import time
from typing import Any

os.environ["TZ"] = "UTC"
time.tzset()

HELPER = (
    pathlib.Path(__file__).resolve().parent.parent
    / ".config/quickshell/services/nextcloud-calendar.py"
)
spec = importlib.util.spec_from_file_location("nextcloud_calendar", HELPER)
assert spec and spec.loader
helper: Any = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)

HOME = "/remote.php/dav/calendars/tester/"
PASSWORD = "stand-in-app-password"


def ics(*components: str) -> str:
    return "\r\n".join(
        ["BEGIN:VCALENDAR", "VERSION:2.0", *components, "END:VCALENDAR"]
    )


def todo(*lines: str) -> str:
    return "\r\n".join(["BEGIN:VTODO", *lines, "END:VTODO"])


# Nextcloud's own layout: a VEVENT calendar, a Tasks app list (VTODO only), and
# things that are not for us.
COLLECTIONS = {
    HOME + "personal/": {
        "name": "Personal",
        "colour": "#3A87ADFF",
        "components": ["VEVENT"],
        "objects": [
            ics(
                "\r\n".join(
                    [
                        "BEGIN:VEVENT",
                        "UID:meeting",
                        "SUMMARY:Meeting",
                        "DTSTART:20260105T090000Z",
                        "DTEND:20260105T100000Z",
                        # An alarm's own SUMMARY and DURATION are not the event's.
                        "BEGIN:VALARM",
                        "ACTION:EMAIL",
                        "SUMMARY:Reminder",
                        "DURATION:PT5M",
                        "REPEAT:2",
                        "TRIGGER:-PT15M",
                        "END:VALARM",
                        "END:VEVENT",
                    ]
                )
            )
        ],
    },
    HOME + "tasks/": {
        "name": "Tasks",
        "colour": "#f0a000",
        "components": ["VTODO"],
        "objects": [
            ics(todo("UID:plants", "SUMMARY:Water the plants")),
            ics(todo("UID:passport", "SUMMARY:Renew passport", "PRIORITY:1")),
            ics(
                todo("UID:rent", "SUMMARY:Pay rent", "DUE;VALUE=DATE:20260105")
            ),
            ics(
                todo(
                    "UID:taxes",
                    "SUMMARY:File taxes",
                    "DUE:20251231T170000Z",
                    "BEGIN:VALARM",
                    "ACTION:EMAIL",
                    "SUMMARY:Alarm",
                    "TRIGGER:-PT1H",
                    "END:VALARM",
                )
            ),
            ics(
                todo(
                    "UID:done",
                    "SUMMARY:Done long ago",
                    "STATUS:COMPLETED",
                    "COMPLETED:20250101T100000Z",
                )
            ),
            ics(
                todo(
                    "UID:status-only",
                    "SUMMARY:Ticked elsewhere",
                    "STATUS:COMPLETED",
                )
            ),
            ics(
                todo("UID:cancelled", "SUMMARY:Called off", "STATUS:CANCELLED")
            ),
            ics(
                todo(
                    "UID:weekly",
                    "SUMMARY:Take out bins",
                    "DUE:20260102T080000Z",
                    "RRULE:FREQ=WEEKLY",
                ),
                todo(
                    "UID:weekly",
                    "SUMMARY:Take out bins",
                    "DUE:20260109T090000Z",
                    "RECURRENCE-ID:20260109T080000Z",
                ),
            ),
        ],
    },
    HOME + "journal/": {
        "name": "Journal",
        "colour": "",
        "components": ["VJOURNAL"],
        "objects": [],
    },
}


def propstat(inner: str) -> str:
    return (
        f"<d:propstat><d:prop>{inner}</d:prop>"
        "<d:status>HTTP/1.1 200 OK</d:status></d:propstat>"
    )


def home_listing(collections: dict) -> str:
    responses = [
        f"<d:response><d:href>{HOME}</d:href>"
        + propstat("<d:resourcetype><d:collection/></d:resourcetype>")
        + "</d:response>",
        f"<d:response><d:href>{HOME}inbox/</d:href>"
        + propstat(
            "<d:resourcetype><d:collection/><c:schedule-inbox/></d:resourcetype>"
        )
        + "</d:response>",
    ]
    for href, collection in collections.items():
        components = "".join(
            f'<c:comp name="{name}"/>' for name in collection["components"]
        )
        responses.append(
            f"<d:response><d:href>{href}</d:href>"
            + propstat(
                "<d:resourcetype><d:collection/><c:calendar/></d:resourcetype>"
                f"<d:displayname>{collection['name']}</d:displayname>"
                f"<a:calendar-color>{collection['colour']}</a:calendar-color>"
                f"<c:supported-calendar-component-set>{components}</c:supported-calendar-component-set>"
            )
            + "</d:response>"
        )
    return multistatus("".join(responses))


def multistatus(responses: str) -> str:
    return (
        '<?xml version="1.0"?><d:multistatus xmlns:d="DAV:" '
        'xmlns:c="urn:ietf:params:xml:ns:caldav" xmlns:a="http://apple.com/ns/ical/">'
        f"{responses}</d:multistatus>"
    )


class StandIn(http.server.ThreadingHTTPServer):
    reports: list[tuple[str, str, str]]
    failing: set[str]
    dropping: set[str]


def serve(collections: dict) -> StandIn:
    """A stand-in Nextcloud on a free loopback port, answering in a thread.

    `server.reports` records (path, component) for every REPORT, a path in
    `server.failing` answers its REPORTs with a 500, and one in `server.dropping`
    hangs up halfway through its answer.
    """

    class Handler(http.server.BaseHTTPRequestHandler):
        def log_message(self, *arguments: object) -> None:
            pass

        def body(self) -> str:
            return self.rfile.read(
                int(self.headers.get("Content-Length", 0))
            ).decode()

        def answer(self, status: int, text: str = "") -> None:
            data = text.encode()
            self.send_response(status)
            self.send_header("Content-Type", "application/xml; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def authorised(self) -> bool:
            expected = helper.base64.b64encode(
                f"tester:{PASSWORD}".encode()
            ).decode()
            if self.headers.get("Authorization") == f"Basic {expected}":
                return True
            self.answer(401)
            return False

        def do_PROPFIND(self) -> None:
            self.body()
            if not self.authorised():
                return
            if self.path == "/remote.php/dav/":
                self.answer(
                    207,
                    multistatus(
                        "<d:response><d:href>/remote.php/dav/</d:href>"
                        + propstat(
                            "<d:current-user-principal><d:href>"
                            "/remote.php/dav/principals/users/tester/</d:href>"
                            "</d:current-user-principal>"
                        )
                        + "</d:response>"
                    ),
                )
            elif self.path == HOME:
                self.answer(207, home_listing(collections))
            else:
                self.answer(404)

        def do_REPORT(self) -> None:
            body = self.body()
            if not self.authorised():
                return
            collection = collections.get(self.path)
            if collection is None:
                self.answer(404)
                return
            component = "VTODO" if 'name="VTODO"' in body else "VEVENT"
            server.reports.append((self.path, component, body))
            if self.path in server.failing:
                self.answer(500)
                return
            if self.path in server.dropping:
                self.send_response(207)
                self.send_header("Content-Length", "1000")
                self.end_headers()
                self.wfile.write(b"<d:multistatus")
                self.close_connection = True
                return
            objects = [
                text
                for text in collection["objects"]
                if f"BEGIN:{component}" in text
            ]
            if "<c:is-not-defined/>" in body:
                objects = [
                    text for text in objects if "\r\nCOMPLETED:" not in text
                ]
            self.answer(
                207,
                multistatus(
                    "".join(
                        f"<d:response><d:href>{self.path}{index}.ics</d:href>"
                        + propstat(
                            f"<c:calendar-data>{text}</c:calendar-data>"
                        )
                        + "</d:response>"
                        for index, text in enumerate(objects)
                    )
                ),
            )

    server = StandIn(("127.0.0.1", 0), Handler)
    server.reports = []
    server.failing = set()
    server.dropping = set()
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server


def run_helper(server: StandIn) -> dict:
    result = subprocess.run(
        [
            sys.executable,
            str(HELPER),
            "--start",
            "2026-01-01",
            "--end",
            "2026-02-01",
        ],
        capture_output=True,
        text=True,
        timeout=30,
        env={
            **os.environ,
            "NEXTCLOUD_URL": f"http://127.0.0.1:{server.server_port}",
            "NEXTCLOUD_USER": "tester",
            "NEXTCLOUD_APP_PASSWORD": PASSWORD,
        },
        check=False,
    )
    return json.loads(result.stdout)


failures: list[str] = []


def check(label: str, got: object, want: object) -> None:
    ok = got == want
    print(f"  [{'ok  ' if ok else 'FAIL'}] {label}")
    if not ok:
        failures.append(f"{label}: wanted {want!r}, got {got!r}")


def main() -> int:
    # The parser on its own.
    [task] = helper.parse_tasks(
        ics(todo("SUMMARY:Call\\, then write", "PRIORITY:x")), "Tasks"
    )
    check("undated task", (task["due"], task["allDay"]), ("", False))
    check("summary unescaped", task["summary"], "Call, then write")
    check("malformed priority is unset", task["priority"], 0)
    check(
        "all-day due is local midnight",
        helper.parse_tasks(ics(todo("DUE;VALUE=DATE:20260105")), "Tasks")[0][
            "due"
        ],
        "2026-01-05T00:00:00",
    )
    [event] = helper.parse_ics(
        COLLECTIONS[HOME + "personal/"]["objects"][0], "Personal"
    )
    check("alarm leaves the event's summary", event["summary"], "Meeting")
    check("alarm leaves the event's end", event["end"], "2026-01-05T10:00:00")
    check(
        "an event the parser cannot read costs only itself",
        [
            event["summary"]
            for event in helper.parse_ics(
                ics(
                    "BEGIN:VEVENT\r\nSUMMARY:Broken\r\nDTSTART:2026-01-05\r\nEND:VEVENT",
                    "BEGIN:VEVENT\r\nSUMMARY:Fine\r\nDTSTART:20260105T090000Z\r\nEND:VEVENT",
                ),
                "Personal",
            )
        ],
        ["Fine"],
    )

    # End to end.
    server = serve(COLLECTIONS)
    payload = run_helper(server)
    check("status", (payload["status"], payload["message"]), ("ok", ""))
    check(
        "open tasks, dated first, then by priority",
        [task["summary"] for task in payload["tasks"]],
        [
            "File taxes",
            "Take out bins",
            "Pay rent",
            "Renew passport",
            "Water the plants",
        ],
    )
    check(
        "due times",
        [task["due"] for task in payload["tasks"]],
        [
            "2025-12-31T17:00:00",
            "2026-01-02T08:00:00",
            "2026-01-05T00:00:00",
            "",
            "",
        ],
    )
    check(
        "a task list's name and colour",
        (payload["tasks"][0]["calendar"], payload["tasks"][0]["colour"]),
        ("Tasks", "#f0a000"),
    )
    check(
        "events still fetched",
        [event["summary"] for event in payload["events"]],
        ["Meeting"],
    )
    check(
        "each collection asked for what it holds",
        sorted(
            (path.removeprefix(HOME), component)
            for path, component, _ in server.reports
        ),
        [("personal/", "VEVENT"), ("tasks/", "VTODO")],
    )
    check(
        "completed tasks left to the server",
        all(
            "<c:is-not-defined/>" in body
            for _, component, body in server.reports
            if component == "VTODO"
        ),
        True,
    )

    server.reports.clear()
    server.failing = {HOME + "tasks/"}
    payload = run_helper(server)
    check(
        "a task list lost costs only its tasks",
        (
            payload["status"],
            payload["message"],
            len(payload["events"]),
            payload["tasks"],
        ),
        ("ok", "could not read Tasks", 1, []),
    )

    server.failing = set()
    server.dropping = {HOME + "tasks/"}
    payload = run_helper(server)
    check(
        "a connection lost mid-answer costs only that list",
        (
            payload["status"],
            payload["message"],
            len(payload["events"]),
            payload["tasks"],
        ),
        ("ok", "could not read Tasks", 1, []),
    )
    server.dropping = set()

    server.failing = {HOME + "tasks/", HOME + "personal/"}
    check("everything lost is an error", run_helper(server)["status"], "error")
    server.shutdown()

    print()
    if failures:
        print(f"FAILED ({len(failures)})")
        for failure in failures:
            print("  -", failure)
        return 1
    print("nextcloud-tasks: all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
