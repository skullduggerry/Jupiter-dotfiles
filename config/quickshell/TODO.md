# TODO

## Phase 1 — Fix what's broken ✅ earlier pass
- [x] Bluetooth popup crash: `btPopup` was referenced but never defined — added
      a minimal read-only popup (`bar/widgets/BluetoothWidget.qml`).
- [x] Battery color bug: percentage `Text` used `Colors.text` (an object)
      instead of `Colors.text.base` (a color).
- [x] Battery icon glyphs: real Nerd Font glyphs, tiered by charge %, instead
      of placeholder strings `"charging"` / `"temp"`.
- [x] Battery colors added to `Colors.qml` (`battery.normal/low/critical/charging`),
      mirroring the existing `bluetooth` group.
- [x] `launcher/qmldir` added — was the one folder module missing explicit
      type registration.
- [x] Indentation standardized to 4 spaces project-wide (mixed tabs/spaces
      before). `.editorconfig` was described as added but never actually
      committed — it exists now (see Phase 2.5).

## Phase 2 — Round out the bar ✅ earlier pass
- [x] Workspaces widget (`bar/widgets/WorkspaceWidget.qml`) for the `left` Row
      in `BarContent.qml`, using `Quickshell.Hyprland` (`Hyprland.workspaces`,
      `Hyprland.monitorFor()`, `HyprlandWorkspace.activate()`). Filters to the
      bar's own monitor via a `screen` property threaded down from
      `Bar.qml` → `BarContent.qml`.
- [x] Bluetooth popup: connect/disconnect, pairing state.
- [x] Bluetooth popup: click-outside-to-close, via shared
      `bar/widgets/WidgetPopup.qml`, reused by Wi-Fi and the power menu.
- [x] Network/Wi-Fi widget + popup (`bar/widgets/WifiWidget.qml`).
- [x] Volume/audio widget (`bar/widgets/VolumeWidget.qml`), via
      `Quickshell.Services.Pipewire` — click to mute, scroll to adjust.
- [x] System tray (`bar/widgets/SystemTrayWidget.qml`).
- [x] Power/session menu (`bar/widgets/PowerWidget.qml`): lock/logout/
      suspend/reboot/shutdown.

  Notes / follow-ups from that pass:
  - "Lock" shells out to `hyprlock` (`Quickshell.execDetached(["hyprlock"])`).
    There's no native Quickshell lock screen yet — that's the Phase 4 "Lock
    screen" item below — so this is an interim dependency. Swap the command
    in `PowerWidget.qml` if you use `swaylock` or another locker.
  - "Logout" runs `Hyprland.dispatch("exit")` (equivalent to
    `hyprctl dispatch exit`), which quits the compositor.

## Phase 2.5 — Correctness pass ✅ earlier pass

Several widgets from Phase 2 were shipped but never actually worked. The
common cause was an API assumption that fails **silently** rather than
erroring, so nothing showed up in the log.

### The `ObjectModel` mistake (the big one)
`Bluetooth.devices`, `Networking.devices`, `SystemTray.items`,
`NetworkDevice.networks` and friends are Quickshell `ObjectModel`s, **not**
QML `ListModel`s. An `ObjectModel` exposes exactly one way to read its
contents from JS: the `values` list. It has **no `count` and no `get(i)`**.

Reading `.count` yields `undefined`, and `for (let i = 0; i < undefined; i++)`
simply never iterates — no exception, no warning, just a binding that quietly
evaluates to its default. Verified against the installed
`/usr/lib/qt6/qml/Quickshell/**/**.qmltypes` and at runtime.

- [x] `SystemTrayWidget`: `visible: SystemTray.items.count > 0` was
      `undefined > 0` → **the tray never rendered at all**, despite four live
      items on this system. Now `SystemTray.items.values.length`.
- [x] `WifiWidget`: the `DeviceType.Wifi` lookup loop never ran, so `device`
      was permanently `null` → **the whole widget was invisible**. Now
      `Networking.devices.values.find(...)`.
- [x] `BluetoothWidget`: the connected-device check never ran, so the bar icon
      was pinned to "disconnected" regardless of state. Now
      `Bluetooth.devices.values.some(...)`.
- [x] The "No networks found" empty state compared `undefined === 0` and so
      could never appear.

  `ListView.count` is fine and still used — that's a real `ListView` property,
  not the model's.

### Other real bugs
- [x] `BatteryWidget` percentage scale: `UPowerDevice.percentage` is a
      **0.0–1.0 ratio** (Quickshell multiplies UPower's wire value by 0.01),
      not 0–100. `Math.round(percentage)` therefore always produced 0 or 1 —
      the bar would have read "0%"/"1%" and always picked the empty-battery
      glyph and the critical color. Now `Math.round(percentage * 100)`.
- [x] `BatteryWidget` charge state: `!UPower.onBattery` only means AC is
      present, so a laptop sitting at 100% on the charger showed the charging
      bolt forever. Now uses `UPowerDeviceState.Charging` / `PendingCharge`,
      with `FullyCharged` sharing the charging color.
- [x] `SystemTrayWidget` menus: `display()` was passed `Window.window` (the
      `QtQuick.Window` `QQuickWindow`) instead of the Quickshell window. Now
      `QsWindow.window`, positioned with `QsWindow.itemRect()` so the menu
      opens under its own icon.
- [x] **Tray menus additionally required `//@ pragma UseQApplication`** in
      `shell.qml`. Without it quickshell logs
      `Cannot display PlatformMenuEntry as quickshell was not started in
      QApplication mode` and no menu appears. Added. **This one needs a full
      quickshell restart — a config reload will not pick it up.**
- [x] `WifiWidget` scanner leak: clicking the widget set
      `device.scannerEnabled = true` and nothing ever set it back, leaving the
      adapter scanning forever (llm.md §15). Now a declarative `Binding` ties
      `scannerEnabled` to the popup's visibility.
- [x] Tray items now also handle middle-click (`secondaryActivate()`) and fall
      back to `secondaryActivate()` on right-click when an item has no menu.

### Design-system alignment (llm.md §6/§7)
- [x] `Colors.text.muted` added. Secondary labels, inline row actions and
      empty states were using `Colors.base.border` — a *border* color that
      happened to look about right.
- [x] `Colors.base.surface` added. The translucent panel fill was spelled out
      as `Qt.rgba(Colors.base.base.r, ...)` in three separate files.
- [x] `Colors.base.hover` added, replacing hardcoded `Qt.rgba(1, 1, 1, 0.08)`
      in `PowerAction.qml` and `LauncherContent.qml`.
- [x] `Colors.status.error` added for inline failure text.
- [x] `Style` gained `widgets.padding` / `widgets.iconSize`,
      `text.iconSize` / `text.smallSize`, `popup.gap` / `popup.rowIconWidth`,
      a `launcher` group and an `animation` group — replacing the magic `+ 16`
      widget padding, `size + 2` icon sizing, `size - 2` small text, and the
      launcher's `300`/`400`/`40`/`32`/`24`/`6` literals.
- [x] Popup row labels no longer subtract magic numbers (`width - 90`,
      `width - 60`) to leave room for their siblings; they derive the
      remaining width from the sibling items directly.
- [x] The Wi-Fi popup body is anchored between its header and its status line
      instead of guessing `parent.height - 40` (llm.md §8).
- [x] `BatteryWidget.device` is typed `UPowerDevice` rather than `var`, and
      `VolumeWidget.adjust()` takes a typed `real` (llm.md §4).

### Honest handling of unsupported states (llm.md §14)
- [x] Wi-Fi connection failures are surfaced inline in the popup instead of
      silently doing nothing. A network needing a PSK NetworkManager doesn't
      already know reports "password required (not supported yet)"; every
      other failure shows `ConnectionFailReason.toString(reason)`.
- [x] The Wi-Fi popup header doubles as an on/off toggle
      (`Networking.wifiEnabled`), and reports "Blocked" when
      `wifiHardwareEnabled` is false, instead of only displaying "(off)" with
      no way to act on it.
- [x] Bluetooth rows use the real `BluetoothDevice.pairing` property, showing
      "Pairing…" and disabling the action while an attempt is in flight.

### Tooling
- [x] `.editorconfig` actually added this time (4 spaces, LF, UTF-8).
- [x] `.qmlls.ini` created so quickshell enables QML language-server support —
      it previously logged `Not enabling QML tooling support, qmlls.ini is
      missing`. Quickshell replaces the file with a symlink into its runtime
      dir, so it's gitignored rather than tracked.
- [x] `qmllint -I /usr/lib/qt6/qml <files>` passes on every file except
      `launcher/Launcher.qml`. That is **not** a code problem: qmllint 1.0
      segfaults on any `function f(): void` annotation, and `IpcHandler`
      requires those annotations. Exclude that one file when linting.

## Phase 3 — New features ✅ earlier pass

### Nextcloud calendar integration
- [x] Fetch method: CalDAV against `/remote.php/dav/calendars/<user>/` from
      `services/nextcloud-calendar.py`, run through `Quickshell.Io.Process`.
      PROPFIND to list the user's VEVENT collections, then one
      `calendar-query` REPORT per calendar with a `time-range` filter.
- [x] Parse the response in the helper, not in QML — but with the standard
      library only (`urllib` + `ElementTree` + a small RFC 5545 unfolder), as
      neither `icalendar` nor `caldav` is installed and a time-range query
      needs very little of either. **Recurrence is expanded server-side**
      (RFC 4791 `<C:expand/>`), so nothing here interprets an `RRULE`.
- [x] `services/CalendarService.qml` singleton. Its contract with the helper
      is one JSON object on stdout — `{"status": "ok"|"unconfigured"|"error",
      ...}` — so a missing config or a dead server is a state the panel can
      display rather than an exception.
- [x] Calendar dropdown UI (`dropdown/CalendarPanel.qml`): month grid with a
      dot under every day that has events, click a day for its agenda, click
      the month name to jump back to today. It's the middle zone of the swipe
      dropdown below, and what the bar's clock opens.
- [x] Credentials never reach QML: `NEXTCLOUD_URL` / `NEXTCLOUD_USER` from the
      environment, and the app password from the session keyring via
      `secret-tool` (`NEXTCLOUD_APP_PASSWORD` also works). See README.

  Notes from that pass:
  - The fetch window is exactly the 42 days the grid shows, so paging months
    refetches that month and nothing else, and the dots never lie about a day
    that wasn't fetched.
  - Against llm.md §15, the service does **nothing at all** while no calendar
    surface is open: `active` (held by a `Binding` for the panel's lifetime)
    gates both the first fetch and the 15-minute refresh.
  - Events are grouped into `eventsByDay` once per fetch instead of being
    filtered per cell — 42 lookups rather than 42 scans of the event list.
  - **Untested against a real Nextcloud.** The request building, both
    responses, the ICS parsing and every error path were exercised against a
    local fake CalDAV server and synthetic ICS; a live server's exact dialect
    hasn't been seen. Run the helper on its own first (README) — it prints
    what it found or what went wrong.

### Wi-Fi password prompt
- [x] `bar/widgets/WifiPanel.qml` now has a `TextInput` row that appears
      either when `connectionFailed(NoSecrets)` comes back or, better, *before*
      connecting to a network that isn't `known` and whose security wants a
      PSK — no point waiting for a failure that's already predictable.
      Enter joins with `connectWithPsk()`, Escape dismisses.
- [x] `WidgetPopup` gained a `keyboardFocus` property (still `None` by
      default) instead of hardcoding it. The Wi-Fi popup raises it while, and
      only while, the prompt is up.
- [x] It raises it to **`Exclusive`, not `OnDemand`**: the popup surface maps
      unfocused and only later asks for focus, so a compositor that hands
      on-demand focus out when a layer surface maps would never give this one
      focus at all. Exclusive is dropped again the moment the prompt is
      answered or dismissed, and a click outside still closes the popup.
- [x] Enterprise networks (EAP/LEAP, WPA3 Suite-B 192) get an honest "needs
      <type> credentials (not supported)" rather than a password box that
      couldn't work: `WifiNetwork` only exposes `connectWithPsk()`, and those
      modes need an identity and usually a certificate.

  Not exercised: actually joining a network that needs a password. There was
  no such network to hand, so the prompt has been driven only as far as the
  `connectWithPsk()` call.

### Three-finger swipe-down → zone-based dropdowns
- [x] **No gesture daemon needed.** The note below about Hyprland being
      workspace-swipe-only predates the 0.49 gesture rework: on the 0.56.2
      installed here, `hl.gesture` takes an `action` *callback table*
      (`start`/`update`/`end`/`finish`), and `hl.get_cursor_pos()` returns
      `{x, y}` in the same logical layout coordinates the shell sees. All
      three were verified against the running compositor rather than assumed,
      so `libinput-gestures`/`fusuma` was dropped from the plan entirely.
- [x] The gesture lives in `../hypr/modules/keybinds.lua` next to the
      existing horizontal workspace swipe, and shells out to
      `qs ipc call dropdown openAt <x> <y>` — one process per gesture, and
      only on the gesture.
- [x] `IpcHandler { target: "dropdown" }` in `dropdown/Dropdown.qml`, with
      `openAt(x, y)`, `open(zone)` and `close()`, following the exact
      `IpcHandler` pattern already in `Launcher.qml`.
- [x] One shared overlay `PanelWindow` that swaps content by zone through a
      `Loader`, built per open and destroyed on close.
- [x] Zone boundaries are thirds of **the monitor the pointer is on** —
      `DropdownState.screenAt()` finds it from `Quickshell.screens` (a plain
      QML list, not an `ObjectModel`), and the thirds are measured inside it.
- [x] The right zone shows the bar's own `WifiPanel` rather than a second
      copy of the network list, which is why that panel was extracted.
- [x] The left zone is a workspace overview (`dropdown/WorkspacePanel.qml`):
      the workspaces on that monitor with their window titles. Clicking a
      workspace activates it; clicking a window calls the toplevel's own
      `wayland.activate()` rather than building a `focuswindow address:`
      dispatcher string.
- [x] The dropdown opens under the zone that triggered it — left zone against
      the left edge, middle centred, right against the right edge — which is
      the Phase 4 complaint below, fixed for this surface at least.

  Not exercised: the swipe itself. There's no way to inject a touchpad
  gesture from a shell, so the Lua block was verified to load without config
  errors and its callback shape probed live, and the
  `qs ipc call dropdown openAt` it runs was driven by hand for all three
  zones.

## Phase 4 — Polish ✅ earlier pass

- [x] Launcher: empty-state message when `filtered` is empty.
- [x] Launcher: icon fallback when `Quickshell.iconPath` can't resolve — falls
      back to a Nerd Font glyph rather than another theme lookup, because the
      failure mode here is usually "no icon theme configured at all" (see
      README).
- [x] Clock: date next to the time, and a click opens the calendar dropdown
      on that monitor. Seconds are a one-line switch rather than the default:
      `Time.showSeconds` also raises the `SystemClock` precision, and there's
      no reason to wake the shell sixty times a minute unless something is
      actually displaying the digit.

### Lock screen
- [x] Native `WlSessionLock` in `lock/`, authenticating through
      `Quickshell.Services.Pam` against the `login` pam.d stack — the same one
      `/etc/pam.d/hyprlock` is a one-line include of. `pam_unix` verifies the
      calling user through the setuid `unix_chkpwd` helper, so quickshell
      needs no privileges of its own.
- [x] State in `services/LockService.qml` rather than next to the window, for
      the reason `DropdownState` is: the bar's power menu, the compositor's
      keybind and every monitor's surface all touch it, and `bar/widgets`
      must not import `lock/`.
- [x] The typed buffer is shared across monitors through a `Binding` on each
      field's `text` — a plain `text:` binding breaks on the first keystroke,
      because typing writes to that property directly.
- [x] `PowerWidget`'s "Lock" and Hyprland's `SUPER+L` both go through it now;
      the `hyprlock` exec is gone from both. hyprlock stays installed and can
      still be run by hand.
- [x] No IPC unlock, on purpose. `qs ipc call lock lock` locks and
      `lock locked` reports; only a password unlocks.

  Verified in a nested Hyprland rather than on the live session: the surface
  maps on every monitor, the field takes active focus, PAM runs the
  conversation and a wrong password comes back "Incorrect password", the
  `quickshell:lock` global shortcut fires the lock, and clearing
  `LockService.locked` drops it. **A successful unlock was not exercised** —
  that needs the real password.

### Popups under their own widget
- [x] `WidgetPopup` takes an `anchorItem` and centres on it, clamped to the
      bar's side margins, instead of every popup opening top-right. Measured
      with `QsWindow.itemRect()` on open — it's a plain method, not a bindable
      property — and re-measured when the widget moves, which it does when a
      tray item appears.
- [x] The two windows use different coordinate frames (the popup covers the
      screen; the bar starts `Style.bar.sideGap` in) and `QsWindow` exposes no
      absolute position, so that token reconciles them.
- [x] `Style.popup.topMargin` no longer double-counts the bar. A full-screen
      overlay is already placed below the bar's exclusive zone, so adding the
      bar's height again left a 55px gap under a 35px bar.

### Escape closes popups
- [x] `WidgetPopup` and the swipe dropdown both take `WlrKeyboardFocus.OnDemand`
      while open, wrap their content in a `FocusScope`, and close on
      `Keys.onEscapePressed`.
- [x] OnDemand alone is not enough: an on-demand layer surface only gets focus
      when the user interacts with *it*, and the click that opens a popup
      lands on the bar. `HyprlandFocusGrab` is what makes the compositor hand
      focus over — verified by watching `activeFocus` with the grab and
      without it — and hand it back on close.
- [x] Side effect worth having: a grab supersedes any grab already out, so
      opening a second popup closes the first. Popups behave like a menu bar
      now.
- [x] The Wi-Fi panel's `Keys.onEscapePressed` leaves the event unaccepted
      when no prompt is up, so Escape backs out of the prompt first and the
      surface second.

  The trade-off, which the old note in this file called out: a popup that
  holds focus interrupts whatever you were typing in. Focus returns on close.

### Zone panels size themselves
- [x] `preferredHeight` is now part of the zone-panel contract next to
      `wantsKeyboard`; `Dropdown.qml` clamps it to
      `Style.dropdown.minHeight`/`maxHeight`. A two-network Wi-Fi list no
      longer sits in a box sized for a month grid.
- [x] `WifiWidget`'s popup uses the same number, so the bar's Wi-Fi popup is
      content-sized too — matching what the Bluetooth popup already did.

### Calendar rework
- [x] The grid draws only the weeks the month occupies (four to six) instead
      of a fixed six, which left an entirely out-of-month row under most
      months.
- [x] Today keeps an accent ring wherever it is; the selected day is a filled
      accent circle with inverted text. Before, both were "today" and you
      couldn't tell them apart.
- [x] Up to three event dots per day rather than one, hover feedback on days
      and chevrons, and a `WheelHandler` so scrolling over the grid pages
      months (a pointer handler, because the per-cell `MouseArea`s would eat a
      wheel event).
- [x] An empty day shows **what's coming instead** — the next few events in
      the fetched window, each labelled with its own date, under a
      `13 Sep · upcoming` header.
- [x] The agenda's leading column is fixed-width, so summaries line up instead
      of stepping in and out with "all day" vs "09:30".

  Exercised against a throwaway local CalDAV server with synthetic events —
  dots, multi-day events, the agenda and the upcoming list. A live Nextcloud
  still hasn't been seen.

### Housekeeping
- [x] `Time` moved from `bar/widgets/` to `services/`. Three surfaces read it
      now (bar, month grid, lock screen), which is what `services/` is for,
      and it means `lock/` and `dropdown/` no longer import `bar/widgets` just
      for a clock.
- [x] Remaining hard-coded values removed: the launcher's backdrop is
      `Colors.base.scrim`, its search font `Style.text.largeSize`, and the
      four `Style.bar.radius / 2` spellings are `Style.popup.rowRadius`.
- [x] The launcher follows the focused monitor (`Hyprland.focusedMonitor`
      matched to a `ShellScreen` by output name) rather than always opening on
      `screens[0]`. That is what the in-code "wrap it in Variants" TODO was
      after; Variants would have put a launcher on *every* screen.
- [x] Hyprland: `qs` is autostarted (`modules/start.lua`) — without it the
      `SUPER+O` and `SUPER+L` global shortcuts and the swipe gesture have
      nothing to talk to. Blur layer rules for the popups and the dropdown
      (`styles/layout.lua`), matching the bar's. `misc:allow_session_lock_restore`
      in a new `modules/session.lua`, so a lock client that dies doesn't
      strand the session.

## Phase 5 — Loose ends ✅ this pass

- [x] `modules/start.lua` no longer launches waybar; `qs` replaced it rather
      than joining it. `config/waybar/` is untouched and still works if you
      run `waybar` by hand — which is how its brightness icon got copied into
      this shell in the first place.
- [x] Launcher results are ordered by launch count, alphabetical within a tie.
      `services/LauncherHistory.qml` persists the counts as JSON under
      `Quickshell.statePath()` through `FileView` + `JsonAdapter`.
      **Keyed on `execString`**, because `DesktopEntry` exposes no id of its
      own on 0.3.1 (`DesktopEntries.byId()` exists, but the entries don't
      carry one) and `name` moves with the locale.
- [x] `Colors.qml` has one palette again. `"blue"`, `"red"`, `"purple"` and
      `"orange"` were plain CSS colour names sitting next to One Dark hexes
      and reading far harsher than them; there is now a `Colors.accent` group
      holding One Dark's seven, and every feature colour refers to it.
- [x] The lock survives a config reload. `LockService.locked` lives in
      `PersistentProperties` now, so saving a QML file while the screen is
      locked no longer drops the lock. Reload state is in memory, not on
      disk, so killing quickshell outright still clears it — which is the
      escape hatch, and the reason this can't strand a session.

  Three bugs found while testing this lot, all the same shape and all
  recorded in PROJECT_STRUCTURE.md under "FileView is asynchronous unless you
  make it otherwise":
  - `LauncherHistory` wrote an empty adapter over a full file on the first
    launch of each session, because a QML singleton is built on first use and
    `blockLoading` is only honoured from `text()`/`data()`. **This destroyed
    history**, and was only caught by running the test twice.
  - Two `record()` calls in one tick lost one of them: `writeAdapter()` is
    asynchronous and a second write started mid-flight resyncs the adapter
    from the first one's snapshot. Writes are debounced now.
  - `Brightness` read nothing at all, because it read from
    `onDeviceChanged` — a property change handler runs before the bindings
    that depend on it, so the `FileView`'s path was still empty.

  Still open:
  - [ ] A successful PAM unlock has never been exercised — it needs the real
        password. Nor has joining a Wi-Fi network that needs one, nor the
        swipe gesture itself.
  - [ ] **The brightness widget has never run against a real backlight.**
        `/sys/class/backlight` is empty on this machine (desktop monitors
        only), so discovery, parsing and the refresh were verified against a
        fake sysfs tree in a scratch directory, and `swayosd-client` was
        never actually invoked.
  - [ ] The calendar's "upcoming" list only knows about the days the grid
        fetched, so late in a month it has less to show.

## Phase 6 — The design file, pass 1 ✅ this pass

Working from `Main-Desktop` in Figma. The file is drawn at **2x** — its canvas
is 2880x1920, which is eDP-1's native mode, and that output runs at `scale = 2`
— so every figure in it is halved to reach logical pixels. That checks out
against what was already built: bar height 66→33 (was 35), top gap 16→8
(exactly what was there), inactive dot 21→10.5 (was 10).

It is also, in the author's words, largely placeholder content with an
inconsistent design language, so it is a direction rather than a spec.

### Bar
- [x] Workspaces are dots, not pills, and sized **between** the design and
      what was there: the design's 10.5 dot growing to 21 on a 31 pitch takes
      a third of the bar, so this is 8 growing to 16 on a 24 pitch. Each dot
      sits in a fixed-width cell, so the row stops shifting every dot to the
      right of the active one when it grows.
- [x] Three dot states rather than two: active, occupied, empty.
- [x] CPU and memory meters next to them (`SystemUsageWidget`). The design
      draws bare percentages; these keep the number small and muted and put a
      thin fill bar under it, which answers "does this matter" before you have
      read anything. Amber past 80%.
- [x] `services/SystemUsage.qml` reads `/proc/stat` and `/proc/meminfo`
      through `FileView` — verified that `reload()` + `text()` is synchronous
      on a procfs file before relying on it. CPU is a delta between samples;
      memory is `MemTotal - MemAvailable`, so page cache isn't counted as
      used. **This is the only genuine poll in the shell**; nothing signals a
      kernel counter moving.
- [x] Battery is the design's outlined pill with the charge as an inner fill
      and the number on top, rather than a glyph plus a percentage.
- [x] Bar glyphs scaled down (`text.iconSize` 15→13, tray `widgets.iconSize`
      22→18). The clock was left at its existing size.
- [x] **Load meters redesigned** after review: the percentage-over-a-fill-bar
      version read as clutter. They are one glyph each now — a circle that
      fills — which is the pattern the waybar config used for `backlight`
      (`"format": "{icon}"`, a nine-step ramp, no text).
- [x] A brightness widget joins them, using that waybar ramp verbatim, so the
      two ramps stay distinguishable: brightness fills like a moon, load fills
      like a pie.
- [x] A hairline between the workspace dots and the load ramps
      (`BarSeparator`). The design file has one — its hidden "Rectangle 6" —
      and it earns its place, because both groups are circles and without it
      the left of the bar reads as one undifferentiated row of them.

### Dropdowns
- [x] The workspace dots open a workspace dropdown: the design's tile grid,
      each tile outlined and carrying its window count, because a tile that
      only says "3" can't tell you whether anything is on it. Named
      workspaces (`special:magic`) elide instead of running into the next
      tile.
- [x] The battery pill opens a battery dropdown (`panels/BatteryPanel.qml`):
      state, time to full/empty, draw, health, model. The design sketches
      this as an empty rectangle, so the contents are whatever `UPowerDevice`
      actually exposes — and a row the device doesn't report is omitted
      rather than shown as a zero (llm.md §14).

### `panels/` — a new module
- [x] `WifiPanel`, `WorkspacePanel`, `CalendarPanel` and the new
      `BatteryPanel` are each opened from two surfaces: a bar widget's
      `WidgetPopup` and a zone of the gesture dropdown. `WifiPanel` used to
      live in `bar/widgets` with `dropdown/` reaching sideways into it; with
      four shared panels that stopped scaling, so they have a module of their
      own that imports only `services/` and `style/`.
- [x] The dependency graph is now a DAG with two leaves (`style/`,
      `services/`), one shared layer (`panels/`) and the surfaces on top.

  Deliberately **not** done this pass:
  - The calendar dropdown was left alone — it is already where it should be.
  - The clock keeps its existing font and its date. The design makes it much
    larger and drops the date; the smaller one was kept on request.
  - Volume, the system tray and the power button stay in the bar. The design
    has none of them, presumably because they move into its tray flyout —
    which is a later pass, and removing them before it exists would be a
    regression.
  - The notification bell and the tray-expand button are **not** in the bar
    yet. Both are entry points to panels that don't exist, and two dead icons
    is worse than two missing ones.
  - The search box is untouched. It is the most placeholder-looking thing in
    the file ("Lorem Ipsum Dolores" / "Entry 1"), and moving the working
    launcher into the bar on the strength of it seemed premature.

## Phase 7 — The rest of the design file

Decided but not started:

- [ ] **Notification centre.** `Quickshell.Services.Notifications` exists
      (`NotificationServer`, `Notification`, `NotificationAction`,
      `NotificationUrgency`). **`swaync` currently owns
      `org.freedesktop.Notifications`** and the two cannot coexist, so this
      pass has to disable swaync's autostart. Note the design sketches the
      *centre* but not the popup toast, which also becomes the shell's job.
- [ ] **Settings app**, as a `FloatingWindow`: theme, accent colour and font,
      persisted through `FileView` + `JsonAdapter` and applied live. Every
      widget already reads `Colors.*`/`Style.*`, so making those derive from a
      config file is contained — but Light mode means authoring a second
      palette, since every colour today assumes dark.
- [ ] **Tray flyout**: six quick-toggle tiles. Backends that exist here:
      `hyprsunset` (Night Light), `power-profiles-daemon` (Power Mode),
      `rfkill` (Airplane Mode), and DND once the shell owns notifications.
      **Not installed: `cliphist`** (so Clipboard has no history to read) and
      **no screen recorder at all** (`wf-recorder`/`wl-screenrec`) — those two
      tiles need a package first.
- [ ] **Wallpaper selector app** plus the wallpaper section of the workspace
      dropdown, over `hyprpaper` IPC, including the design's per-workspace
      apply.
- [ ] The bar's notification bell and tray-expand button, once their panels
      exist.
- [ ] The search box, if it should replace the fullscreen launcher rather
      than sit alongside it.
