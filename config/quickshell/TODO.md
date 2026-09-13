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

## Phase 3 — New features ✅ this pass

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

## Phase 4 — Polish
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
- [ ] Lock screen.
- [ ] `WidgetPopup` anchors every popup to the top-right of the screen, so the
      Bluetooth, Wi-Fi and power dropdowns all open in the same place rather
      than under the icon that opened them. Threading the owning item through
      and offsetting from it would fix this; left alone for now because it's
      cosmetic and crosses a window boundary (the popup is a separate
      `PanelWindow` from the bar). The swipe dropdown already places itself
      per zone (`dropdown/Dropdown.qml`), so there's a shape to copy.
- [ ] `WidgetPopup` defaults to `WlrKeyboardFocus.None`, so popups still can't
      be dismissed with Escape — only by clicking outside. The property is no
      longer hardcoded (see Phase 3), so a popup that wants Escape can now ask
      for focus; nothing does yet, because holding focus for a click-driven
      menu would steal it from whatever the user was typing in.
- [ ] The dropdown's Wi-Fi and workspace zones sit in a panel sized for the
      month grid, so a short network list leaves empty space below it. Either
      let a zone panel declare a preferred height, or accept one geometry for
      all three (which is what it does now, deliberately).
