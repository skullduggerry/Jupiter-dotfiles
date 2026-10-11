#!/usr/bin/env python3
"""The QML tests: each tests/qml/*Test.qml, run inside Quickshell itself.

Every file gets a Quickshell of its own (tests/qml/shell.qml runs its test_
functions), offscreen and in a throwaway home with nothing of the session
around it: no display, no D-Bus, no Hyprland, nothing on PATH. A test can
use any singleton, and a service that reaches for the desktop fails here
instead of acting on it. A file named Greeter*Test.qml runs the way the
login screen does, with HOME=/nonexistent and no XDG folders.

A test fails on a FAIL line, and so does its file on any warning or error
Quickshell logs, as the running shell would show them in its log, except
those a test let through with ignoreWarning().
"""

import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import threading

REPO = pathlib.Path(__file__).resolve().parent.parent
TESTS = REPO / "tests" / "qml"
TIMEOUT = 60  # seconds for one file
RESULT = re.compile(r"\bqml: (PASS|FAIL|DONE|IGNORE)\b ?(.*)")
PROBLEM = re.compile(r"^\s*(WARN|ERROR|FATAL|CRITICAL)\b")


def environment(test: pathlib.Path, root: pathlib.Path) -> dict[str, str]:
    runtime = root / "run"
    runtime.mkdir(mode=0o700)
    env = {
        "PATH": str(root / "bin"),
        "LANG": "C.UTF-8",
        "TZ": "UTC",
        "XDG_RUNTIME_DIR": str(runtime),
        "QT_QPA_PLATFORM": "offscreen",
        "DBUS_SESSION_BUS_ADDRESS": "unix:path=/nonexistent",
        "DBUS_SYSTEM_BUS_ADDRESS": "unix:path=/nonexistent",
        "QML_TEST": str(test),
    }
    if test.name.startswith("Greeter"):
        return env | {"HOME": "/nonexistent"}
    home = root / "home"
    return env | {
        "HOME": str(home),
        "XDG_CONFIG_HOME": str(home / ".config"),
        "XDG_CACHE_HOME": str(home / ".cache"),
        "XDG_DATA_HOME": str(home / ".local/share"),
        "XDG_STATE_HOME": str(home / ".local/state"),
    }


def run(test: pathlib.Path, qs: str) -> list[str]:
    """The failures in one file, as lines to print."""
    failures = []
    ignored = []
    log = []
    done = False
    # Quickshell's IPC socket lives in the runtime folder, and a socket's
    # path must stay short: no deep temporary folder.
    with tempfile.TemporaryDirectory(prefix="qmltest.", dir="/tmp") as tmp:
        root = pathlib.Path(tmp)
        command = [qs, "--no-color", "-p", str(TESTS / "shell.qml")]
        with subprocess.Popen(
            command,
            env=environment(test, root),
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        ) as process:
            watchdog = threading.Timer(TIMEOUT, process.kill)
            watchdog.start()
            assert process.stdout is not None
            for line in process.stdout:
                line = line.rstrip("\n")
                log.append(line)
                if match := RESULT.search(line):
                    kind, text = match.groups()
                    if kind == "FAIL":
                        failures.append(text)
                    elif kind == "IGNORE":
                        ignored.append(re.compile(text))
                    elif kind == "DONE":
                        done = True
                        break
                elif PROBLEM.match(line) and not any(
                    pattern.search(line) for pattern in ignored
                ):
                    failures.append(line.strip())
            process.terminate()
            watchdog.cancel()
    if not done:
        failures.append("never finished; its log:")
        failures.extend(log[-20:])
    return failures


def main() -> int:
    qs = shutil.which("qs")
    if qs is None:
        print("qml-test: qs (quickshell) is not installed", file=sys.stderr)
        return 1
    only = sys.argv[1:]
    failed = 0
    for test in sorted(TESTS.glob("*Test.qml")):
        if only and test.stem not in only:
            continue
        failures = run(test, qs)
        print(f"{'FAIL' if failures else 'ok  '}  {test.name}")
        for failure in failures:
            print(f"      {failure}")
        failed += bool(failures)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
