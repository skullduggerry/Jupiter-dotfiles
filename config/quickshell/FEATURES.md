# Features

Everything this shell does, surface by surface. `README.md` covers setup and
dependencies, `PROJECT_STRUCTURE.md` the file layout and conventions, and
`TODO.md` what is left.

Quickshell **0.3.1**, Hyprland **0.56.2**, Arch Linux. Every API used here was
checked against `/usr/lib/qt6/qml/Quickshell/**/*.qmltypes` on that install.

---

## Surfaces at a glance

| Surface | Where it lives | Opened by |
| --- | --- | --- |
| Bar | `bar/` | always on, one per monitor |
| Widget popups | `bar/widgets/WidgetPopup.qml` | clicking a bar widget |
| Swipe dropdown | `dropdown/` | three-finger swipe down, or the bar's clock |
| Launcher | `launcher/` | `SUPER+O`, or `qs ipc call launcher toggle` |
| Lock screen | `lock/` | `SUPER+L`, the power menu, or `qs ipc call lock lock` |

Shared singletons live in `services/` (data and cross-surface state) and
`style/` (every colour and every dimension). Panel *content* shown by more
than one surface lives in `panels/` — the workspace tiles, the month grid, the
network list and the battery details are each opened both from a bar widget
and from a zone of the swipe dropdown.

---

## The bar

One `PanelWindow` per screen, via `Variants { model: Quickshell.screens }`.
Floating: 8px off the top, 14px in from each side, rounded, translucent, with
an exclusive zone so tiled windows sit below it. Hyprland blurs it
(`qs-bar-blur` in `../hypr/styles/layout.lua`).

Each bar knows which monitor it is on and passes that `ShellScreen` down to
every widget that needs it, so popups open on the right screen and the
workspace dots show the right workspaces.

### Workspaces — `bar/widgets/WorkspaceWidget.qml`

- Dots for the Hyprland workspaces **on this monitor**, filtered from the
  global `Hyprland.workspaces` through `Hyprland.monitorFor(screen)`.
- Three states, not two: active, occupied (has windows), empty.
- The active dot grows (animated) inside a fixed-width cell, so the row keeps
  its geometry instead of shifting every dot to the right of it.
- Click a dot to switch, via `HyprlandWorkspace.activate()` — no `hyprctl`
  dispatcher strings. Click the row itself for the workspace dropdown
  (`panels/WorkspacePanel.qml`), the same tile grid the swipe dropdown's left
  zone shows.

### CPU and memory — `bar/widgets/SystemUsageWidget.qml`

- Two glyphs next to the workspaces, no text: a circle that fills as load
  rises, amber past 80%. Same idea as the brightness ramp in the waybar
  config this shell replaces — `"format": "{icon}"` and nothing else.
- The ramp is `nf-md-circle-outline` plus `nf-md-circle-slice-1..8`, so step 0
  is genuinely empty. Brightness uses a different ramp (below) so the three
  stay distinguishable: that one fills like a moon, these fill like a pie.
- CPU first, memory second, told apart by position — a letter beside each
  would cost more in clutter than it bought in precision.
- Fed by `services/SystemUsage.qml`, which reads `/proc/stat` and
  `/proc/meminfo` through `FileView` rather than a `cat` subprocess. CPU is a
  delta between samples; memory counts `MemTotal - MemAvailable`, so page
  cache isn't reported as used.
- One of only two things in the shell that poll. Nothing tells you when a
  kernel counter moves; the interval is 3s and `active` gates the timer.

### Brightness — `bar/widgets/BrightnessWidget.qml`

- One glyph from the nine-step ramp the waybar config used for `backlight`,
  copied verbatim, so it reads exactly as it did there. Scroll to adjust.
- `services/Brightness.qml` finds the device by listing
  `/sys/class/backlight` once (there is no directory API — `FileView` reads a
  file), then reads `brightness` against `max_brightness`.
- Writes go through `swayosd-client`, which the compositor's brightness keys
  already use: it owns the privileged write path and shows the on-screen
  level, so there is one mechanism rather than two.
- The level is **re-read on a timer, not watched**. A `FileView` watch was
  tried first and never fired: sysfs attributes support `poll()` on an open
  descriptor, not the inotify events `QFileSystemWatcher` subscribes to. Since
  the brightness keys go through swayosd rather than through the shell, their
  changes have to be noticed rather than observed.
- Hidden entirely when `/sys/class/backlight` is empty — a desktop, or this
  laptop docked with its lid shut.

### Clock — `bar/widgets/ClockWidget.qml`

- Time and short date, in the bar's centre zone.
- Click opens the calendar zone of the dropdown on this monitor.
- Seconds are one flag away (`Time.showSeconds`), which also raises the
  `SystemClock` precision — off by default so the shell isn't woken sixty
  times a minute to redraw a digit.

### System tray — `bar/widgets/SystemTrayWidget.qml`

- Icons from `Quickshell.Services.SystemTray`, hidden entirely when empty.
- Left-click activates, middle-click secondary-activates, right-click opens
  the item's DBus menu (falling back to secondary-activate when it has none).
- Menus are platform menus, so `shell.qml` carries `//@ pragma UseQApplication`
  — without it quickshell logs `Cannot display PlatformMenuEntry` and nothing
  opens. That pragma needs a full restart, never just a config reload.

### Volume — `bar/widgets/VolumeWidget.qml`

- The PipeWire default sink, tracked with a `PwObjectTracker` so its audio
  properties stay populated and writable.
- Glyph tiers by level, turns amber when muted; percentage next to it.
- Click toggles mute, scroll adjusts in 5% steps (unmuting as it goes).
- Hidden while there is no ready sink.

### Wi-Fi — `bar/widgets/WifiWidget.qml` + `panels/WifiPanel.qml`

- Bar glyph tiers by `signalStrength` (a 0.0–1.0 ratio), and shows a distinct
  "off" glyph when `Networking.wifiEnabled` is false.
- The popup is `WifiPanel`, which the dropdown's right zone reuses rather than
  keeping a second copy of the network list:
  - header doubles as an on/off toggle, and reports **Blocked** when the
    hardware rfkill switch is off;
  - the scanned networks, each with an inline Connect/Disconnect;
  - **password prompt** for a network NetworkManager has no stored secret
    for. It appears *before* connecting to an unknown PSK network rather than
    after the failure comes back. Enter joins with `connectWithPsk()`, Escape
    backs out;
  - enterprise modes (EAP/LEAP, WPA3 Suite-B 192) say "needs `<type>`
    credentials (not supported)" instead of showing a password box that
    couldn't work — `WifiNetwork` only exposes `connectWithPsk()`;
  - failures are surfaced inline, so a click never looks like it did nothing.
- The adapter scans **only while the panel is on screen**, held by a `Binding`
  on `scannerEnabled` rather than turned on from a click handler.

### Bluetooth — `bar/widgets/BluetoothWidget.qml`

- Bar glyph reflects whether anything is connected.
- Popup lists `Bluetooth.devices` with a per-row action: Disconnect when
  connected, Connect when paired, Pair otherwise. A pairing attempt in flight
  shows "Pairing…" and disables the row.
- Popup height follows the device count.

### Battery — `bar/widgets/BatteryWidget.qml`

- `UPower.displayDevice`, hidden entirely when it isn't a laptop battery.
- An outlined pill whose inner fill is the charge, with the percentage on top
  of it — the fill goes amber under 30% and red under 15%, and a bolt joins
  the number while charging.
- Click for the battery dropdown (`panels/BatteryPanel.qml`): state, time to
  full or empty, power draw, cell health and model. Rows the device doesn't
  report are left out rather than shown as zeroes — a battery with no
  `healthSupported` gets no Capacity row at all.
- `UPowerDevice.percentage` is a **0.0–1.0 ratio**, not 0–100, and charge
  state comes from `UPowerDeviceState`, not from `!UPower.onBattery`.

### Power menu — `bar/widgets/PowerWidget.qml`

Lock · Logout · Suspend · Reboot · Shutdown, the last two in the danger
colour. Lock raises this shell's own lock screen through `LockService`;
logout is `Hyprland.dispatch("exit")`; the rest are `systemctl`.

---

## Widget popups — `bar/widgets/WidgetPopup.qml`

The shared dropdown shell behind the Bluetooth, Wi-Fi and power menus. One
full-screen transparent overlay window with the panel drawn on top of it.

- **Anchored under the widget that opened it.** The popup centres on its
  `anchorItem`, clamped to the bar's own side margins so a popup belonging to
  the rightmost widget sits flush with the bar's right edge instead of hanging
  off screen. The anchor is measured with `QsWindow.itemRect()` when the popup
  opens and re-measured if the widget moves (a tray item appearing shifts
  everything to its left).
- **Escape closes it**, and so does a click anywhere outside. Escape needs
  keyboard focus, and an on-demand layer surface only gets focus when the user
  interacts with *it* — the click that opens a popup lands on the bar, a
  different surface. `HyprlandFocusGrab` is what makes the compositor hand
  focus over and hand it back on close.
- **Only one at a time.** A focus grab supersedes any grab already out, so
  opening a second popup (or the swipe dropdown) closes the first, the way a
  menu bar behaves.
- Sized by its content: each caller computes `popupHeight` from what it is
  showing, clamped to `Style.popup.minHeight`/`maxHeight`.
- Each popup takes its own layer-shell namespace (`quickshell:wifi-popup`, …)
  so compositor rules can target one specifically. Hyprland blurs all of them
  through one `^quickshell:.*-popup$` rule.

The trade-off of holding focus: clicking a bar widget now interrupts whatever
you were typing in. Focus returns when the popup closes.

---

## Swipe dropdown — `dropdown/`

A three-finger swipe down opens one dropdown, its content chosen by which
third of the monitor the pointer is over: **left** workspaces, **middle**
calendar, **right** Wi-Fi. Swiping over the same zone closes it; over a
different one swaps the content.

- **No gesture daemon.** Hyprland 0.49+ gesture actions can be Lua callbacks,
  so `../hypr/modules/keybinds.lua` reads `hl.get_cursor_pos()` and calls
  `qs ipc call dropdown openAt <x> <y>` — one process per gesture, and only on
  the gesture.
- The zone decision lives in the shell (`services/DropdownState.qml`), taken
  against the monitor the pointer is on, so it behaves the same on every
  screen. `Quickshell.screens` is a plain QML list, indexed directly.
- One overlay window for all three zones, swapping content through a `Loader`
  that is **built per open and destroyed on close** — a closed dropdown does
  no calendar polling, no Wi-Fi scanning and holds no window-list bindings.
- It opens under the zone that triggered it: left against the left edge, right
  against the right, middle centred.
- Escape closes it, on the same focus-grab mechanism as the widget popups.
- **Each zone panel declares the height it wants.** `preferredHeight` is part
  of the zone-panel contract alongside `wantsKeyboard`; `Dropdown.qml` clamps
  it to `Style.dropdown.minHeight`/`maxHeight`. A two-network Wi-Fi list no
  longer sits in a box sized for a month grid.

### Left zone — `panels/WorkspacePanel.qml`

The workspaces on this monitor as a grid of outlined tiles, each showing its
name and how many windows are on it. Clicking a tile activates that workspace.
Named workspaces (Hyprland's `special:magic`) elide rather than run into their
neighbour.

### Middle zone — `panels/CalendarPanel.qml`

- Month grid with **only the weeks the month occupies** (four to six), so
  September doesn't get an entirely out-of-month sixth row.
- **Today** keeps an accent ring wherever it is; the **selected** day is a
  filled accent circle with inverted text; hovering any day washes it.
- **Event dots** under each day, one per event up to three.
- Chevrons page months and highlight on hover; the month name is also a
  "back to today" button; **scrolling over the grid** pages months (a
  `WheelHandler`, so the per-cell `MouseArea`s don't eat the event).
- Below the grid, the selected day's agenda — time in the accent colour,
  summary elided, columns aligned.
- When the selected day has nothing on it, the agenda shows **what's coming
  instead** — the next few events in the fetched window, each labelled with
  its own date, under a `13 Sep · upcoming` header. An empty day no longer
  means an empty panel.
- The fetch state has its own line: the last sync time when things are fine,
  a setup hint while the calendar is unconfigured, the failure otherwise.

### Right zone

`panels/WifiPanel.qml`, the same panel the bar's Wi-Fi widget shows.

---

## Nextcloud calendar — `services/CalendarService.qml`

- CalDAV against `/remote.php/dav/calendars/<user>/`: a PROPFIND to list the
  user's VEVENT collections, then one `calendar-query` REPORT per calendar
  with a `time-range` filter.
- All of that happens in `services/nextcloud-calendar.py`, **standard library
  only** (`urllib` + `ElementTree` + a small RFC 5545 unfolder), run through
  `Quickshell.Io.Process`. Recurrence is expanded server-side (RFC 4791
  `<C:expand/>`), so nothing here interprets an `RRULE`.
- The helper's contract is **one JSON object on stdout** —
  `{"status": "ok"|"unconfigured"|"error", ...}` — so a missing config or a
  dead server is a state the panel displays, not an exception.
- **Credentials never reach QML.** `NEXTCLOUD_URL` and `NEXTCLOUD_USER` come
  from the environment, the app password from the session keyring via
  `secret-tool` (or `NEXTCLOUD_APP_PASSWORD`), read by the script.
- The grid drives the fetch window: exactly the days on screen, so paging
  refetches that month and nothing else and the dots never lie about a day
  that wasn't fetched.
- **Nothing runs while no calendar surface is open.** `active`, held by a
  `Binding` for the panel's lifetime, gates both the first fetch and the
  15-minute refresh. Month paging is debounced so a burst of clicks is one
  request.
- Events are grouped into `eventsByDay` once per fetch, so the grid answers
  its cells with lookups rather than scans. A multi-day event lands on each of
  its days; an all-day event's exclusive `DTEND` is respected.

---

## Launcher — `launcher/`

- Fuzzy-ish filter over `DesktopEntries.applications` by name and comment,
  **ordered by how often you launch each one** and alphabetical within a tie,
  so a fresh install still reads as an alphabetical list and drifts towards
  what you use.
- Counts live in `services/LauncherHistory.qml`, persisted as JSON under
  `Quickshell.statePath()` via `FileView` + `JsonAdapter`. Keyed on
  `execString`, because `DesktopEntry` exposes no id of its own on this
  version and `name` moves with the locale.
- Up/Down to move, Enter to launch, Escape to close, click to launch.
- Built only while open — an eager launcher scanned every desktop entry and
  rendered an icon per app into a window nobody was looking at.
- Icons via `Quickshell.iconPath(name, true)`, with a Nerd Font glyph fallback
  for entries no installed theme can resolve.
- Empty-state message when nothing matches.
- **Opens on the focused monitor**: `Hyprland.focusedMonitor` matched to a
  `ShellScreen` by output name, since `HyprlandMonitor` carries no screen of
  its own. One window that follows the focus, rather than one per screen.
- Triggered by a `GlobalShortcut` (`quickshell:launcherToggle`, no process
  spawn per press) or `qs ipc call launcher toggle`.

---

## Lock screen — `lock/` + `services/LockService.qml`

A native `WlSessionLock`, replacing the `hyprlock` process the power menu used
to spawn.

- One `WlSessionLockSurface` per monitor: clock, date, password field, and the
  user it belongs to.
- Authentication is `Quickshell.Services.Pam` against the `login` pam.d stack
  — the same one `/etc/pam.d/hyprlock` includes. `pam_unix` verifies the
  calling user through the setuid `unix_chkpwd` helper, so quickshell does not
  need to be privileged.
- The field shows a busy glyph and an accent ring while PAM holds the attempt,
  and goes read-only so a sent buffer can't be edited.
- A wrong password reports **Incorrect password**, `PamResult.MaxTries`
  reports **Too many attempts**, and a PAM stack that won't even start says so
  by name rather than blaming the password.
- The typed buffer is **shared across monitors**, so typing shows up wherever
  you started. Each field keeps it through a `Binding` rather than a plain
  `text:` assignment, which typing would break on the first keystroke.
- `LockService.locked` is the authority. PAM success clears it, the
  `WlSessionLock` binding follows, and the compositor drops the lock.
- **There is deliberately no IPC unlock.** `qs ipc call lock lock` locks and
  `qs ipc call lock locked` reports the state; nothing unlocks but a password.

Triggers: `SUPER+L` (the `quickshell:lock` global shortcut), the bar's power
menu, or the IPC call.

See `README.md` for the two caveats that come with owning your own locker: a
config reload while locked drops the lock, and recovery from a crashed lock
client depends on `misc:allow_session_lock_restore`, which
`../hypr/modules/session.lua` turns on.

---

## Design system

Nothing hard-codes a colour or a dimension.

- **`style/Colors.qml`** — every colour, grouped semantically: `text`
  (`base`/`muted`/`inverted`), `base` (`border`/`base`/`panel`/`surface`/
  `hover`/`scrim`), and a group per feature (`bluetooth`, `battery`, `wifi`,
  `volume`, `workspaces`, `calendar`, `power`, `status`, `lock`).
- **`style/Style.qml`** — every spacing, size, radius and font: `bar`,
  `border`, `widgets`, `text`, `popup`, `workspaces`, `launcher`, `animation`,
  `dropdown`, `calendar`, `lock`.

Derived tokens are composed in `Style.qml` rather than spelled out at call
sites — `popup.topMargin`, `calendar.daySize`, `popup.rowRadius`.

---

## Compositor integration

Everything the shell needs from Hyprland, and nothing it doesn't.

| Concern | How |
| --- | --- |
| Workspaces, monitors, toplevels | `Quickshell.Hyprland` reactive models — no polling, no `hyprctl` spawning |
| Launcher / lock shortcuts | `GlobalShortcut`, bound with `hl.dsp.global(...)` |
| Swipe gesture | `hl.gesture` with a Lua `finish` callback calling `qs ipc` |
| Popup focus | `HyprlandFocusGrab` |
| Blur | `hl.layer_rule` per namespace, in `../hypr/styles/layout.lua` |
| Lock-crash recovery | `misc:allow_session_lock_restore`, in `../hypr/modules/session.lua` |
| Autostart | `hl.exec_cmd("qs")` in `../hypr/modules/start.lua` |

---

## Things the codebase knows that aren't obvious

Collected here because each one cost a real bug. `PROJECT_STRUCTURE.md` has
the longer versions.

- Quickshell services hand you an **`ObjectModel`**, not a `ListModel`. It has
  **no `count` and no `get(i)`** — read it through `values`, or bind it
  straight to a view. `.count` evaluates to `undefined`, `i < undefined` is
  `false`, and the loop silently never runs. Three widgets shipped broken this
  way with a completely clean log.
- `UPowerDevice.percentage`, `WifiNetwork.signalStrength` and
  `PwNodeAudio.volume` are **0.0–1.0 ratios**, not 0–100.
- A QML function whose return value is read from a binding **needs a return
  type annotation**, or every call site logs an error — 42 of them, for a
  month grid.
- A full-screen overlay window is already positioned **below the bar's
  exclusive zone**; adding the bar's height to its top margin counts it twice.
- Binding a wrapping `Text`'s own `height` to its own `implicitHeight` is a
  layout loop. Wrap it in an `Item` that reads the child's implicit height.
