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

## Phase 2 — Round out the bar
- [ ] Workspaces widget for the empty `left` Row in `BarContent.qml`, using
      `Quickshell.Hyprland` (already imported in `Launcher.qml`, unused there).
- [ ] Bluetooth popup: connect/disconnect, pairing state (the `pairing` color
      in `Colors.qml` is defined but still unused).
- [ ] Bluetooth popup: click-outside-to-close (needs a fullscreen transparent
      catcher window, same trick as the launcher's dimmed backdrop).
- [ ] Network/Wi-Fi widget + popup: SSID, signal strength, connect/disconnect list.
- [ ] Volume/audio widget (Pipewire via Quickshell services).
- [ ] System tray (`Quickshell.Services.SystemTray`).
- [ ] Power/session menu (lock/logout/suspend/shutdown).

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
