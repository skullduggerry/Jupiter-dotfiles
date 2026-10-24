#!/usr/bin/env python3
"""Tasks in nextcloud-calendar.py: which collections hold them, which of them
are open, the order the calendar dropdown lists them in, and marking one done.

The helper runs end to end against a stand-in CalDAV server on loopback (the
one place it accepts plain http), which answers the way Nextcloud does: a
principal, a calendar home listing each collection's components, REPORTs
that honour the COMPLETED filter, and objects to GET and PUT under an ETag. Its timezone is UTC, so due times read back
exactly as written.

    python3 tests/nextcloud-tasks-test.py        exit 0 on success
"""

from __future__ import annotations

import copy
import hashlib
import http.server
import importlib.util
import json
import os
import pathlib
import subprocess
import sys
import threading
import time
from datetime import UTC, datetime
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


def tasks_in(text: str) -> list[list[str]]:
    """Each VTODO's lines in an object as the helper writes it, unfolded."""
    found: list[list[str]] = []
    for line in helper.unfold(text):
        if line == "BEGIN:VTODO":
            found.append([])
        elif found and found[-1][-1:] != ["END:VTODO"]:
            found[-1].append(line)
    return [task[:-1] for task in found]


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
    puts: list[tuple[str, str]]


def etag(text: str) -> str:
    return '"' + hashlib.sha1(text.encode()).hexdigest() + '"'


def serve(collections: dict) -> StandIn:
    """A stand-in Nextcloud on a free loopback port, answering in a thread.

    `server.reports` records (path, component) for every REPORT, a path in
    `server.failing` answers its REPORTs with a 500, and one in `server.dropping`
    hangs up halfway through its answer. An object is `<collection><index>.ics`,
    and `server.puts` records (path, If-Match) for every PUT.
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
                (index, text)
                for index, text in enumerate(collection["objects"])
                if f"BEGIN:{component}" in text
            ]
            # As the server matches it: an object is open while any task in
            # it is, the main one beside a record of an occurrence done.
            if "<c:is-not-defined/>" in body:
                objects = [
                    (index, text)
                    for index, text in objects
                    if any(
                        "\r\nCOMPLETED:" not in part
                        for part in text.split("BEGIN:VTODO")[1:]
                    )
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
                        for index, text in objects
                    )
                ),
            )

        def stored(self) -> tuple[list[str], int] | None:
            """The collection's objects and this path's index in them."""
            collection, _, name = self.path.rpartition("/")
            objects = collections.get(collection + "/", {}).get("objects")
            index = name.removesuffix(".ics")
            if objects is None or not index.isdigit():
                return None
            if int(index) >= len(objects):
                return None
            return objects, int(index)

        def do_GET(self) -> None:
            if not self.authorised():
                return
            found = self.stored()
            if found is None:
                self.answer(404)
                return
            objects, index = found
            data = objects[index].encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/calendar; charset=utf-8")
            self.send_header("ETag", etag(objects[index]))
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def do_PUT(self) -> None:
            body = self.body()
            if not self.authorised():
                return
            found = self.stored()
            if found is None:
                self.answer(404)
                return
            objects, index = found
            match = self.headers.get("If-Match", "")
            server.puts.append((self.path, match))
            if match and match != etag(objects[index]):
                self.answer(412)
                return
            objects[index] = body
            self.answer(204)

    server = StandIn(("127.0.0.1", 0), Handler)
    server.reports = []
    server.failing = set()
    server.dropping = set()
    server.puts = []
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server


def run_helper(server: StandIn, *arguments: str) -> dict:
    result = subprocess.run(
        [
            sys.executable,
            str(HELPER),
            *(arguments or ("--start", "2026-01-01", "--end", "2026-02-01")),
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

    stamp = datetime(2026, 1, 3, 12, tzinfo=UTC)
    marked = helper.mark_completed(
        ics(
            todo(
                "UID:plants",
                "SUMMARY:Water the plants",
                "STATUS:IN-PROCESS",
                "PERCENT-COMPLETE:40",
                "BEGIN:VALARM",
                "ACTION:DISPLAY",
                "STATUS:ignored-here",
                "TRIGGER:-PT1H",
                "END:VALARM",
            )
        ),
        stamp,
    )
    check(
        "done as the Tasks app marks it, the alarm untouched",
        marked.split("\r\n"),
        [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "BEGIN:VTODO",
            "STATUS:COMPLETED",
            "PERCENT-COMPLETE:100",
            "COMPLETED:20260103T120000Z",
            "LAST-MODIFIED:20260103T120000Z",
            "UID:plants",
            "SUMMARY:Water the plants",
            "BEGIN:VALARM",
            "ACTION:DISPLAY",
            "STATUS:ignored-here",
            "TRIGGER:-PT1H",
            "END:VALARM",
            "END:VTODO",
            "END:VCALENDAR",
            "",
        ],
    )
    long = "SUMMARY:" + "ä" * 60
    folded = helper.mark_completed(ics(todo(long)), stamp)
    check(
        "long lines folded within 75 octets, and unfold back",
        (
            max(len(line.encode()) for line in folded.split("\r\n")) <= 75,
            long in helper.unfold(folded),
        ),
        (True, True),
    )
    check(
        "a changed instance is not the task",
        "COMPLETED:"
        in helper.mark_completed(
            ics(
                todo("UID:a", "RECURRENCE-ID:20260109T080000Z"),
                todo("UID:a", "SUMMARY:Main"),
            ),
            stamp,
        )
        .split("SUMMARY:Main")[0]
        .split("RECURRENCE-ID")[1],
        True,
    )
    try:
        helper.mark_completed(ics(), stamp)
        check("an object without a task is refused", "accepted", "refused")
    except helper.Failed:
        check("an object without a task is refused", "refused", "refused")

    # A repeating task: only this occurrence done, as Nextcloud Tasks does it.
    [task, record] = tasks_in(
        helper.mark_completed(
            ics(
                todo(
                    "UID:bins",
                    "SUMMARY:Take out bins",
                    "PRIORITY:5",
                    "DTSTART:20260101T080000Z",
                    "DUE:20260102T080000Z",
                    "RRULE:FREQ=WEEKLY;COUNT=3",
                    "STATUS:NEEDS-ACTION",
                )
            ),
            stamp,
        )
    )
    check(
        "moved on to the next, start and due a day apart still, one fewer left",
        task,
        [
            "DUE:20260109T080000Z",
            "LAST-MODIFIED:20260103T120000Z",
            "DTSTART:20260108T080000Z",
            "RRULE:FREQ=WEEKLY;COUNT=2",
            "UID:bins",
            "SUMMARY:Take out bins",
            "PRIORITY:5",
        ],
    )
    check(
        "the occurrence recorded done",
        record,
        [
            "UID:bins",
            "SUMMARY:Take out bins",
            "PRIORITY:5",
            "RECURRENCE-ID:20260102T080000Z",
            "DUE:20260102T080000Z",
            "DTSTART:20260101T080000Z",
            "STATUS:COMPLETED",
            "PERCENT-COMPLETE:100",
            "COMPLETED:20260103T120000Z",
            "LAST-MODIFIED:20260103T120000Z",
            "DTSTAMP:20260103T120000Z",
        ],
    )

    def moved(*lines: str) -> list[str]:
        """The task's own lines after marking it done, alarms aside."""
        return tasks_in(helper.mark_completed(ics(todo(*lines)), stamp))[0]

    check(
        "the clock in its zone kept across the change from summer time",
        moved("DUE;TZID=Europe/Berlin:20261024T090000", "RRULE:FREQ=DAILY")[0],
        "DUE;TZID=Europe/Berlin:20261025T090000",
    )
    check(
        "a whole day stays one, on the rule's weekdays",
        moved("DUE;VALUE=DATE:20260105", "RRULE:FREQ=WEEKLY;BYDAY=MO,TH")[0],
        "DUE;VALUE=DATE:20260108",
    )
    check(
        "from a day off the rule, to its first day",
        moved("DUE;VALUE=DATE:20260106", "RRULE:FREQ=WEEKLY;BYDAY=SU")[0],
        "DUE;VALUE=DATE:20260111",
    )
    check(
        "only a start date moves that",
        moved("DTSTART:20260105T090000", "RRULE:FREQ=DAILY;INTERVAL=2")[0],
        "DTSTART:20260107T090000",
    )
    for label, lines in (
        (
            "the last of a count",
            ("DUE:20260105T090000Z", "RRULE:FREQ=DAILY;COUNT=1"),
        ),
        (
            "past the rule's end",
            (
                "DUE:20260105T090000Z",
                "RRULE:FREQ=DAILY;UNTIL=20260105T235959Z",
            ),
        ),
        (
            "past the rule's last day",
            ("DUE;VALUE=DATE:20260105", "RRULE:FREQ=WEEKLY;UNTIL=20260111"),
        ),
    ):
        tasks = tasks_in(helper.mark_completed(ics(todo(*lines)), stamp))
        check(
            f"done for good: {label}",
            [
                ("STATUS:COMPLETED" in task, "RECURRENCE-ID" in str(task))
                for task in tasks
            ],
            [(True, False), (True, True)],
        )
    check(
        "a repeating task with no date is done for good",
        moved("UID:someday", "RRULE:FREQ=WEEKLY")[0],
        "STATUS:COMPLETED",
    )

    # End to end, on a copy, since marking done writes into it.
    server = serve(copy.deepcopy(COLLECTIONS))
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
        "each task carries its object's href",
        {task["summary"]: task["href"] for task in payload["tasks"]},
        {
            "File taxes": HOME + "tasks/3.ics",
            "Take out bins": HOME + "tasks/7.ics",
            "Pay rent": HOME + "tasks/2.ics",
            "Renew passport": HOME + "tasks/1.ics",
            "Water the plants": HOME + "tasks/0.ics",
        },
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
    server.failing = set()

    done = run_helper(server, "--complete", HOME + "tasks/0.ics")
    check("marked done", done, {"status": "ok", "message": ""})
    check(
        "written only over the version read",
        [match.startswith('"') for _, match in server.puts],
        [True],
    )
    check(
        "gone from the open tasks",
        "Water the plants"
        in [task["summary"] for task in run_helper(server)["tasks"]],
        False,
    )
    check(
        "a repeating task marked done",
        run_helper(server, "--complete", HOME + "tasks/7.ics")["status"],
        "ok",
    )
    check(
        "and still open, due next week, its record in the same object",
        (
            [
                task["due"]
                for task in run_helper(server)["tasks"]
                if task["summary"] == "Take out bins"
            ],
            [path for path, _ in server.puts],
        ),
        (
            ["2026-01-09T08:00:00"],
            [HOME + "tasks/0.ics", HOME + "tasks/7.ics"],
        ),
    )
    check(
        "a task already gone is an error",
        run_helper(server, "--complete", HOME + "tasks/99.ics")["status"],
        "error",
    )
    for href in (
        "https://elsewhere.example/remote.php/dav/calendars/x/a.ics",
        "//elsewhere.example/remote.php/dav/calendars/x/a.ics",
        HOME + "../../../../index.php/a.ics",
        "/index.php/apps/a.ics",
    ):
        check(
            f"refused without asking: {href}",
            (
                run_helper(server, "--complete", href)["status"],
                len(server.puts),
            ),
            ("error", 2),
        )
    server.shutdown()

    # Another client changed the task between the read and the write.
    collections: dict[str, Any] = copy.deepcopy(COLLECTIONS)
    racing = serve(collections)
    real_exchange = helper.exchange

    def edited_meanwhile(method: str, url: str, *rest: Any) -> Any:
        answer = real_exchange(method, url, *rest)
        if method == "GET":
            collections[HOME + "tasks/"]["objects"][1] += "\r\n"
        return answer

    helper.exchange = edited_meanwhile
    os.environ.update(
        NEXTCLOUD_URL=f"http://127.0.0.1:{racing.server_port}",
        NEXTCLOUD_USER="tester",
        NEXTCLOUD_APP_PASSWORD=PASSWORD,
    )
    try:
        helper.complete(HOME + "tasks/1.ics")
        outcome = "written"
    except helper.Failed as error:
        outcome = str(error).split(": ", 1)[1]
    finally:
        helper.exchange = real_exchange
    check(
        "another client's change is not written over",
        (outcome, "COMPLETED" in collections[HOME + "tasks/"]["objects"][1]),
        (
            "HTTP 412 Precondition Failed (changed on the server meanwhile)",
            False,
        ),
    )
    racing.shutdown()

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
