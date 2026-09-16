pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string status: "idle"
    property string message: ""
    property var events: []
    property date lastUpdated: new Date(0)
    property date rangeStart: new Date(new Date().getFullYear(), new Date().getMonth(), 1)
    property date rangeEnd: new Date(new Date().getFullYear(), new Date().getMonth() + 1, 1)
    property bool active: false
    property bool refetchWanted: false
    property bool syncWanted: false
    // A fetch is a REPORT per calendar across the network — seconds, not
    // milliseconds — so the panel must not need one to draw. Two things keep
    // it off the critical path: fetching a window much wider than the month
    // on screen, so paging around it costs nothing, and keeping the last
    // answer on disk, so a fresh shell has something to show immediately.
    readonly property int prefetchDays: 120
    readonly property int staleAfter: 5 * 60 * 1000
    property date fetchStart: new Date(0)
    property date fetchEnd: new Date(0)
    property date coveredStart: new Date(0)
    property date coveredEnd: new Date(0)
    readonly property string serverUrl: settings.serverUrl
    readonly property string user: settings.user
    readonly property bool configured: root.serverUrl !== "" && root.user !== ""
    property string loginMessage: ""
    readonly property bool signingIn: login.running
    readonly property bool loading: status === "loading"
    readonly property var eventsByDay: {
        const grouped = {
        };
        for (let index = 0; index < root.events.length; index++) {
            const event = root.events[index];
            let day = new Date(event.start.getFullYear(), event.start.getMonth(), event.start.getDate());
            do {
                const key = root.dayKey(day);
                if (grouped[key] === undefined)
                    grouped[key] = [];

                grouped[key].push(event);
                day = new Date(day.getFullYear(), day.getMonth(), day.getDate() + 1);
            } while (day < event.end && day < root.rangeEnd)
        }
        return grouped;
    }

    // The server address and the login name are not secrets, so they can live
    // in QML and in a state file. The app password still never comes near
    // either: nextcloud-calendar.py reads it from the keyring itself.
    // Whatever page of the web UI got pasted, reduce it to the address the DAV
    // endpoints hang off. Everything from the first Nextcloud-owned segment on
    // is UI, and this keeps a subpath install (https://host/nextcloud) intact.
    function baseAddress(url: string) : string {
        return url.trim().replace(/\/(index\.php|remote\.php|apps|settings|login|u)(\/.*)?$/, "").replace(/\/+$/, "");
    }

    function addressProblem(address: string) : string {
        if (address === "")
            return "Server address is needed";

        // Same rule the helper enforces: https, or plain http only where it
        // cannot leave the machine.
        if (!/^https:\/\//.test(address) && !/^http:\/\/(localhost|127\.0\.0\.1)([:\/]|$)/.test(address))
            return "Needs an https:// address — the app password is sent as HTTP Basic auth";

        return "";
    }

    function configure(url: string, user: string) : string {
        const address = root.baseAddress(url);
        const problem = root.addressProblem(address);
        if (problem !== "")
            return problem;

        const login = user.trim();
        if (login === "")
            return "User is needed, or use Sign in to have the server tell us";

        settings.serverUrl = address;
        settings.user = login;
        settingsFile.writeAdapter();
        root.refresh(true);
        return "";
    }

    // Login Flow v2: the browser authenticates, which is the only thing that
    // works when the account sits behind an SSO provider, and the server
    // answers with the real login name plus a fresh app password.
    function signIn(url: string) : string {
        const address = root.baseAddress(url);
        const problem = root.addressProblem(address);
        if (problem !== "")
            return problem;

        settings.serverUrl = address;
        settingsFile.writeAdapter();
        root.loginMessage = "Opening your browser…";
        login.running = true;
        return "";
    }

    function handleLogin(event) {
        if (event.status === "open") {
            Quickshell.execDetached(["xdg-open", event.url]);
            root.loginMessage = "Finish signing in in your browser…";
        } else if (event.status === "ok") {
            settings.user = event.loginName;
            settingsFile.writeAdapter();
            root.loginMessage = "";
            root.refresh(true);
        } else {
            root.loginMessage = event.message;
        }
    }

    function shift(day: date, days: int) : date {
        return new Date(day.getFullYear(), day.getMonth(), day.getDate() + days);
    }

    function monthStart(day: date) : date {
        return new Date(day.getFullYear(), day.getMonth(), 1);
    }

    function monthAfter(day: date) : date {
        return new Date(day.getFullYear(), day.getMonth() + 1, 1);
    }

    function covers(start: date, end: date) : bool {
        return root.coveredStart.getTime() > 0 && start >= root.coveredStart && end <= root.coveredEnd;
    }

    function stale() : bool {
        return Date.now() - root.lastUpdated.getTime() > root.staleAfter;
    }

    function refresh(force: bool) {
        if (!force && root.covers(root.rangeStart, root.rangeEnd))
            return ;

        if (fetcher.running) {
            root.refetchWanted = true;
            return ;
        }
        root.refetchWanted = false;
        root.status = "loading";
        // Set before running: command is a binding, so the process starts on
        // the window that was just pinned rather than on the visible range.
        // Snapped to whole months so the edges do not wobble with the day of
        // the month, which is what makes the coverage below predictable.
        root.fetchStart = root.monthStart(root.shift(root.rangeStart, -root.prefetchDays));
        root.fetchEnd = root.monthAfter(root.shift(root.rangeEnd, root.prefetchDays));
        fetcher.running = true;
    }

    function dayKey(day: date) : string {
        return Qt.formatDate(day, "yyyy-MM-dd");
    }

    function adopt(raw) {
        root.events = raw.map((event) => {
            return ({
                "summary": event.summary,
                "location": event.location,
                "calendar": event.calendar,
                "colour": event.colour || "",
                "allDay": event.allDay,
                "start": new Date(event.start),
                "end": new Date(event.end)
            });
        });
    }

    // Keep the raw payload rather than the mapped events: it is what the
    // helper printed, so reading it back needs no second format.
    function store(raw) {
        cacheFile.setText(JSON.stringify({
            "start": root.dayKey(root.fetchStart),
            "end": root.dayKey(root.fetchEnd),
            "updated": root.lastUpdated.toISOString(),
            "events": raw
        }));
    }

    function restore() {
        if (!root.configured)
            return ;

        let cached = null;
        try {
            cached = JSON.parse(cacheFile.text());
        } catch (parseError) {
            return ;
        }
        if (!cached || !cached.events)
            return ;

        root.adopt(cached.events);
        root.coveredStart = new Date(cached.start);
        root.coveredEnd = new Date(cached.end);
        root.lastUpdated = new Date(cached.updated);
        root.status = "ok";
    }

    function applyResult(exitCode: int, output: string, errorOutput: string) {
        let payload = null;
        try {
            payload = JSON.parse(output);
        } catch (parseError) {
            root.status = "error";
            root.message = errorOutput.trim().split("\n").pop() || "calendar helper exited " + exitCode + " without output";
            return ;
        }
        root.status = payload.status;
        root.message = payload.message || "";
        if (payload.status === "ok") {
            root.adopt(payload.events);
            root.lastUpdated = new Date();
            root.coveredStart = root.fetchStart;
            root.coveredEnd = root.fetchEnd;
            root.store(payload.events);
        } else if (payload.status === "unconfigured") {
            root.events = [];
            root.coveredStart = new Date(0);
        }
        if (root.refetchWanted)
            root.refresh(false);

    }

    onActiveChanged: {
        // Opening the panel draws from the cache straight away; the network is
        // only asked when what it holds has had time to drift. Going through
        // the debounce rather than fetching here is what stops the first open
        // spending a fetch on the default range: the panel's range bindings
        // arrive a moment after active does.
        if (!root.active)
            return ;

        root.syncWanted = root.stale();
        rangeDebounce.restart();
    }
    onRangeStartChanged: rangeDebounce.restart()
    onRangeEndChanged: rangeDebounce.restart()
    Component.onCompleted: {
        settingsFile.text();
        root.restore();
    }

    Process {
        id: login

        command: ["python3", Quickshell.shellDir + "/services/nextcloud-login.py", "--url", root.serverUrl]
        onExited: (exitCode, exitStatus) => {
            if (root.loginMessage === "Finish signing in in your browser…")
                root.loginMessage = "";

        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                return root.handleLogin(JSON.parse(line));
            }
        }

    }

    Process {
        id: fetcher

        command: ["python3", Quickshell.shellDir + "/services/nextcloud-calendar.py", "--start", root.dayKey(root.fetchStart), "--end", root.dayKey(root.fetchEnd)]
        // Only override what has actually been set here, so NEXTCLOUD_URL from
        // a shell profile still works for anyone who configured it that way.
        environment: {
            const vars = {
            };
            if (root.serverUrl !== "")
                vars["NEXTCLOUD_URL"] = root.serverUrl;

            if (root.user !== "")
                vars["NEXTCLOUD_USER"] = root.user;

            return vars;
        }
        onExited: (exitCode, exitStatus) => {
            return root.applyResult(exitCode, fetchOutput.text, fetchError.text);
        }

        stdout: StdioCollector {
            id: fetchOutput
        }

        stderr: StdioCollector {
            id: fetchError
        }

    }

    FileView {
        id: settingsFile

        path: Quickshell.statePath("nextcloud.json")
        preload: true
        blockLoading: true
        printErrors: false
        watchChanges: false

        adapter: JsonAdapter {
            id: settings

            property string serverUrl: ""
            property string user: ""
        }

    }

    FileView {
        id: cacheFile

        path: Quickshell.statePath("calendar-cache.json")
        preload: true
        blockLoading: true
        printErrors: false
        watchChanges: false
    }

    Timer {
        id: rangeDebounce

        interval: 250
        onTriggered: {
            if (!root.active)
                return ;

            const force = root.syncWanted;
            root.syncWanted = false;
            root.refresh(force);
        }
    }

    Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: root.active
        onTriggered: root.refresh(true)
    }

}
