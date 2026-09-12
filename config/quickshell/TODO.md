# TODO

## Phase 1 — Fix what's broken ✅ done this pass
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
      before); `.editorconfig` added to enforce it going forward.

## Phase 2 — Round out the bar ✅ done this pass
- [x] Workspaces widget (`bar/widgets/WorkspaceWidget.qml`) for the `left` Row
      in `BarContent.qml`, using `Quickshell.Hyprland` (`Hyprland.workspaces`,
      `Hyprland.monitorFor()`, `HyprlandWorkspace.activate()`). Filters to the
      bar's own monitor via a `screen` property threaded down from
      `Bar.qml` → `BarContent.qml`.
- [x] Bluetooth popup: connect/disconnect, pairing state. Uses
      `BluetoothDevice.connect()/disconnect()/pair()`; the `pairing` color in
      `Colors.qml` is now consumed for not-yet-paired devices.
- [x] Bluetooth popup: click-outside-to-close, via new shared
      `bar/widgets/WidgetPopup.qml` (fullscreen transparent catcher window,
      same trick as the launcher's dimmed backdrop — now reused by Wi-Fi and
      the power menu too instead of being re-implemented per widget).
- [x] Network/Wi-Fi widget + popup (`bar/widgets/WifiWidget.qml`): SSID list,
      signal strength, connect/disconnect, via the new `Quickshell.Networking`
      module (`Networking`, `WifiDevice`, `WifiNetwork`). Connecting to a
      network that needs a new PSK isn't wired up (see note below).
- [x] Volume/audio widget (`bar/widgets/VolumeWidget.qml`), via
      `Quickshell.Services.Pipewire` — click to mute, scroll to adjust.
- [x] System tray (`bar/widgets/SystemTrayWidget.qml`), via
      `Quickshell.Services.SystemTray` — left click activates, right click
      (or a menu-only item) opens its context menu.
- [x] Power/session menu (`bar/widgets/PowerWidget.qml`): lock/logout/
      suspend/reboot/shutdown.

  Notes / follow-ups from this pass:
  - "Lock" shells out to `hyprlock` (`Quickshell.execDetached(["hyprlock"])`).
    There's no native Quickshell lock screen yet — that's the Phase 4 "Lock
    screen" item below — so this is an interim dependency. Swap the command
    in `PowerWidget.qml` if you use `swaylock` or another locker.
  - "Logout" runs `Hyprland.dispatch("exit")` (equivalent to
    `hyprctl dispatch exit`), which quits the compositor.
  - Wi-Fi networks that require a PSK Quickshell doesn't already know will
    emit `Network.connectionFailed(NoSecrets)` with no UI to enter one yet —
    `WifiNetwork.connectWithPsk()` exists for this; wiring up a password
    prompt is a reasonable Phase 3-ish follow-up.
  - `Style.qml`/`Colors.qml` gained `popup`, `workspaces`, `wifi`, `volume`,
    and `power` token groups so the new widgets don't hardcode one-off sizes
    or colors (see `llm.md` §6).

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
- [ ] Launcher: empty-state message when `filtered` is empty.
- [ ] Launcher: icon fallback when `Quickshell.iconPath` can't resolve.
- [ ] Clock: seconds/date display, click → open calendar dropdown (Phase 3).
- [ ] Lock screen.
