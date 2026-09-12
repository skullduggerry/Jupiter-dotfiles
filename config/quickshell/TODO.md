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

## Phase 2.5 — Correctness pass ✅ this pass

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

## Phase 3 — New features

### Nextcloud calendar integration
- [ ] Decide fetch method: Nextcloud CalDAV endpoint
      (`/remote.php/dav/calendars/...`) via `Quickshell.Io.Process`, polling
      on an interval — same pattern as `Time.qml`'s singleton.
- [ ] Parse the CalDAV/ICS response — likely a small helper script
      (Python/curl + ical parser) invoked through `Process`, rather than
      parsing raw CalDAV XML in QML.
- [ ] `CalendarService` singleton exposing upcoming events as a model.
- [ ] Calendar dropdown UI (month grid + agenda list) — becomes the
      **middle**-zone content for the swipe gesture below.
- [ ] Store Nextcloud credentials securely — env var or system keyring via a
      helper script, not plaintext in QML.

### Wi-Fi password prompt
- [ ] `WifiNetwork.connectWithPsk(psk)` exists; the popup currently only
      *reports* that a PSK is needed. Add a `TextInput` row that appears when
      `connectionFailed(NoSecrets)` fires (or when `!network.known` and
      `security !== WifiSecurityType.Open`).
      Note this needs `WlrKeyboardFocus.OnDemand` on the popup —
      `WidgetPopup` currently hardcodes `None` since nothing needed typing.

### Three-finger swipe-down → zone-based dropdowns
- [ ] Quickshell/QML doesn't read raw touchpad gestures itself, and
      Hyprland's native gesture support is workspace-swipe-only (not
      position-aware custom actions) — need an external gesture daemon:
      `libinput-gestures` or `fusuma` (simpler config).
- [ ] Gesture daemon detects 3-finger swipe-down + reports pointer X position
      at gesture start.
- [ ] Daemon shells out to `qs -c <config> ipc call <target> <action>` —
      reuse the exact `IpcHandler` pattern already in `Launcher.qml`.
- [ ] New `IpcHandler` (e.g. `target: "dropdown"`) with a function like
      `openAt(x: real)` that decides the zone (left third = workspaces,
      middle third = calendar, right third = wifi) and toggles the right popup.
- [ ] One shared "dropdown shell" `PanelWindow` (same overlay pattern as
      `Launcher.qml`) that swaps its content component based on which zone
      triggered it, instead of three separate windows.
- [ ] Zone boundaries relative to *monitor width*, not global coordinates —
      for multi-monitor setups (`Bar.qml` already handles `Quickshell.screens`,
      so the pattern to follow exists).

## Phase 4 — Polish
- [x] Launcher: empty-state message when `filtered` is empty.
- [x] Launcher: icon fallback when `Quickshell.iconPath` can't resolve — falls
      back to a Nerd Font glyph rather than another theme lookup, because the
      failure mode here is usually "no icon theme configured at all" (see
      README).
- [ ] Clock: seconds/date display, click → open calendar dropdown (Phase 3).
- [ ] Lock screen.
- [ ] `WidgetPopup` anchors every popup to the top-right of the screen, so the
      Bluetooth, Wi-Fi and power dropdowns all open in the same place rather
      than under the icon that opened them. Threading the owning item through
      and offsetting from it would fix this; left alone for now because it's
      cosmetic and crosses a window boundary (the popup is a separate
      `PanelWindow` from the bar).
- [ ] `WidgetPopup` sets `WlrKeyboardFocus.None`, so popups can't be dismissed
      with Escape — only by clicking outside.
