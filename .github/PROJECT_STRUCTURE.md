# Project structure

The map of the repo and the rules the code alone does not show. How to write
code: `.github/llm.md`. Colours across apps: `.github/THEMING.md`.

Installed: Quickshell 0.3.1, Hyprland 0.56.2 (configured in Lua), Qt 6.11, Arch.

## Repo

| Path | What |
| --- | --- |
| `.config/` | linked into `~/.config/` by Jupiter-installer (phase 4), `.zshrc` to `~/.zshrc`; a new folder needs nothing added |
| `.config/quickshell/` | the shell |
| `.config/hypr/` | Hyprland: `hyprland.lua`, `modules/` (binds, monitors, startup, workspaces…), `styles/` (layer rules, blur, animations) |
| `.config/wallust/` | theming, see THEMING.md |
| `etc/greetd/` | the login screen, a second Quickshell config; `scripts/install-greeter.sh` installs it as a copy |
| `scripts/`, `tests/` | `check.sh` and its helpers; Python tests that `check.sh` runs |

Package dependencies belong in Jupiter-installer's `packages/core.txt` and
`aur.txt`, not here.

## The shell

```
shell.qml        builds every surface below
style/           Colors, Style (every token), Theme (palette + appearance.json),
                 LockLook. The greeter gets a copy of this folder.
icons/           Icons (Lucide glyphs by name, vendored lucide.ttf), Icon,
                 BatteryIcon, RingIcon
services/        singletons: data sources and cross-surface state, with their
                 helper scripts (*.py, *.sh)
panels/          content shown by more than one surface, and its parts:
                 PanelFrame, PopupFrame, PillGroup, TextButton, SliderRow, …
bar/             Bar (a PanelWindow per screen) holding BarContent (full bar)
                 or SmallBarContent; BarDrawer; BackdropProbe; widgets/ (one
                 file per widget, WidgetPopup, QuickPager, TrayMenu)
dropdown/        the three-finger-swipe overlay: workspaces, calendar, quick settings
settings/        SettingsApp (window, IPC) + SettingsContent (sidebar, tabs)
                 + one file per page or tab, and their shared parts
lock/ notifications/ osd/ overview/ shortcuts/ cursor/
quickmenu/       one surface each: X.qml (scope, IPC, shortcut) + its content
```

**Imports form a DAG.** `style/` and `services/` import nothing from the
project, `panels/` imports only those two, and every other folder sits on top.
Nothing in `bar/` imports `dropdown/` or `lock/`. State that two surfaces share
lives in `services/` (`DropdownState`, `LockService`, `SettingsState`).

**`style/` must work as the greeter**, which runs as a user without a readable
`$HOME`. It may only read files until a choice is made, start no process while
it is constructed, and never call `Quickshell.statePath()`, because that call
creates the directory. Check with `HOME=/nonexistent`.
`etc/greetd/monitors.lua` is a symlink to `.config/hypr/modules/monitors.lua`,
and the installer must copy it as a file.

## Conventions

- Format with Qt 6's `qmlformat` (`scripts/check.sh --fix`; the pre-commit
  hook formats staged files). `/usr/bin/qmlformat` and `qmllint` are the Qt 5
  versions and mangle Qt 6 syntax, so `check.sh` puts `/usr/lib/qt6/bin` first
  on PATH. Members stay in the order they were written. Don't use
  `--normalize`.
- Every folder's `qmldir` names each of its types (`singleton Time 1.0 Time.qml`).
- `pragma ComponentBehavior: Bound` goes in any file whose delegates read an
  outer id. Delegates take model data as a `required property`, never as the
  implicit `modelData`. Read what a `Loader` holds as a typed value
  (`implicitHeight`, or `(content.item as QuickSettingsPanel)?.step(…)`).
- `Style` and `Colors` groups are inline component types
  (`component BarStyle: QtObject {…}`), so qmllint can check their members.
- **Colours are formulas over `Colors.palette`** (background, foreground and
  six ANSI slots). Only `Colors.overlay`, used for anything drawn over a
  picture under a dark scrim, is a literal.
- **Icons:** every glyph is Lucide. Give it a name in `icons/Icons.qml`,
  written as a `"\u{E059}"` escape and never pasted, and draw it with `Icon`.
  A glyph in any other `Text` needs `font.family: Icons.font`. Every icon is
  `Colors.icon.active`: the glyph alone shows on, off and idle. Colour means
  attention only: a usage meter past its threshold, a low battery, a critical
  notification.
- **Panels are `PanelFrame`s**, which own the padding, the header (`title`,
  `trailing`) and the separator. Hosts add no margins of their own.
- A switch between a few values is a `PillGroup`. A clickable word or glyph is
  a `TextButton`. A level is a `SliderRow` (`VolumeRow` for a PipeWire node).
- Per-user state lives in `Quickshell.statePath(…)` or
  `$XDG_STATE_HOME/quickshell/`, never in the repo, and so do per-machine
  choices (keyboard layouts, monitor rules, the main bar's screen).

## Where things go

| Adding | Goes |
| --- | --- |
| A colour | `style/Colors.qml`, in its feature's group, derived from the palette |
| A size, spacing, radius, font or duration | `style/Style.qml`, in its feature's group |
| A bar widget | `bar/widgets/` + `qmldir` + `BarContent.qml` (the right side: the always-visible row or `BarDrawer`); also `SmallBarContent.qml` if the other screens should show it |
| A widget's dropdown | `WidgetPopup` with `anchorItem`, a `namespaceSuffix` ending in `-popup`, and content as children (see `PowerWidget`) |
| A panel | a `PanelFrame` in `panels/` that sets `implicitHeight` |
| A quick-settings page | a panel + a `page*` index and `Component` in `QuickSettingsPanel` |
| A swipe zone | a panel, a zone in `DropdownState` and its place in `step()`, a `Component` in `Dropdown.qml` |
| Anything fetched from outside | a `services/` singleton, with a helper script run through `Process` |
| A top-level surface | its own folder + `qmldir`, following `shortcuts/` (overlay) or `settings/` (window) |
| A quick-menu item or category | `quickmenu/QuickMenuItems` (`definitions`, `categories`, `shortcuts`); a default slot in `services/QuickMenu` |
| A Settings page or tab | an entry in `SettingsContent.pages` (name, title, glyph, search words, `tabs`) and a `Component` in its `Loader`. Inside it: a `ScrollPage` if it can be taller than the window, a `PanelCard` for a quick-settings panel, `FormCard`/`FormRow` for labelled settings, `Card` for other rows |
| Something that must run from login | a service with an `active` flag, bound from something that is always built (as `SettingsApp.qml` binds `WallpaperService.active`) |
| A surface in the top right | publish its area with `PopupAreas.set()` so toasts move below it |
| A new `-popup` that is not a dropdown | the `qs-not-dropdowns` layer rule in `.config/hypr/styles/layout.lua` |

A widget that needs its monitor declares `required property ShellScreen screen`,
which is passed down from `Bar.qml` through `BarContent`/`SmallBarContent`.

## Surfaces and services

**Popups.** Open and close a `WidgetPopup` or the `Dropdown` with `open`, never
with `visible`: the window stays up while `PopupFrame` animates back into the
bar. While it closes, the mask is empty and the focus grab is released, so
input passes through. The blur comes from Hyprland, not Quickshell: the layer
rule `^quickshell:.*-popup$`. A namespace without the `-popup` suffix renders
flat, and the log says nothing.

**The swoosh setting** (`Theme.swoosh`) switches Hyprland's fade off through
the layer rule `qs-dropdown-swoosh`. `Theme.setSwoosh` enables that rule with
`hyprctl eval` and persists it in `dropdowns.lua`. `qs-not-dropdowns`, declared
after it, re-enables the fade for the OSD and the toasts (the later matching
rule wins). With Swoosh on, or when the new zone is on another screen,
showing another zone while one is open sends the frame back into the bar
first, and the new zone comes out of it.

**A panel's only contract with its host is `implicitHeight`.** Compute it from
intrinsic sizes, never from the panel's own `height` (that is a loop). Hosts
round it down with `Math.floor` so frames don't end mid-pixel.

**The quick-settings pager** (`QuickPager` on the bar, the dropdown's right
zone) is a wrapping `PathView`. Its path must be `pathItemCount` page-widths
long, or the pages overlap. Paging comes from horizontal wheel events on the
popup's full-screen backdrop: the first page of a gesture costs
`Style.pager.swipeStep`, each further page `swipeRepeat`, and `swipeIdle` ends
the gesture. Any `Flickable` in a page needs
`flickableDirection: Flickable.VerticalFlick`, or it eats the swipe. A
two-finger swipe on the touchpad sends a click first, so dismissing waits
`Style.popup.dismissDelay` and any wheel event cancels it. Every page is built
up front, so scanning and searching are gated on being the current page.

**Arrow keys** step through the zones and pages (`DropdownState.step()`,
`QuickSettingsPanel.step(direction, wrap)`), except when
`Window.activeFocusItem instanceof TextInput`.

**OSD** (`osd/`): owns the media keys (`GlobalShortcut`s that Hyprland binds
with `hl.dsp.global`). It takes no input at all (empty `mask`, focus `None`), so
it never steals the keyboard. `OsdState` keeps it and the quick-settings
surfaces from showing at once: `viewers` counts the open surfaces, and a
dropdown opening within `timeout` of a key press starts on that key's page.

**Bars.** `BarLayout.main` (the screen picked in Settings → Displays, stored
by port name in `bar.json`; otherwise the top-left screen) gets the full bar,
and every other screen gets the small pill. Each screen keeps one
`PanelWindow`, and a `Loader` swaps its content, because Caffeine's
`IdleInhibitor` only counts on a surface that was mapped before it was enabled.
The inhibitor binds to `bar.caffeine`, not to `QuickToggles` directly (that
was a binding loop). A small bar may float over windows (`exclusiveZone: 0`),
and then `Dropdown`/`WidgetPopup` add `Style.bar.floatingClearance`
themselves. On a small bar's screen, popups open centred under the pill
(`screen !== BarLayout.main`). The drawer is anchored between two rows rather
than placed in a `Row`, because a `Row` jumps by its spacing at width 0. Its
`clip` stops hidden widgets from taking clicks.

**Power button**: `PowerButton` holds
`systemd-inhibit --what=handle-power-key` while the session is unlocked
(released on lock, retaken 5 s after it ends unasked), and `XF86PowerOff`
opens the power menu. With the shell gone or locked, logind powers off as
usual.

**Quick toggles** (`QuickToggles`, `panels/TogglesPanel`): Night Light is a
`hyprsunset` process the shell owns, and stopping it is the off switch.
Hyprland allows one CTM client, and a second one exits 1. Screen Record is
`wf-recorder`, finished with SIGINT. Clipboard history means two
`wl-paste --watch cliphist store` watchers. Airplane Mode goes through
NetworkManager and BlueZ, not rfkill. Choices persist in `quick-toggles.json`;
tiles show whether the process actually runs. The bars construct
`QuickToggles` (singletons are built on first use), which is what restores
Night Light at login.

**Calendar** (`CalendarService` + `nextcloud-calendar.py`, CalDAV on Nextcloud):
- The UI never waits on the network. The fetched range is padded by
  `prefetchDays` and snapped to whole months, the last answer is cached in
  `calendar-cache.json`, and a fetch only runs past `staleAfter`. Activation
  goes through the debounce. At most 4 REPORTs run in parallel (more failed
  TLS handshakes).
- The server URL and login live in `nextcloud.json` and reach the helper
  through `Process.environment`. The app password stays in the keyring
  (`secret-tool`) and never touches QML, state files or argv. Only `https://`
  is accepted, except loopback. Sign-in uses Login Flow v2
  (`nextcloud-login.py`). The calendar home is discovered through
  `current-user-principal`, never built from the login name.
- `calendar-color` lives in Apple's namespace and arrives as `#rrggbbaa`. Cut
  it to `#rrggbb`, because QML reads eight hex digits as ARGB. Nested
  components (`VALARM`) are skipped. Tasks are the open VTODOs (`COMPLETED`
  not defined), read-only.

**Wallpaper** (`WallpaperService`, hyprpaper 0.8.4 over `hyprctl hyprpaper`):
- The library is `~/Wallpapers`, and its subfolders are the category tabs. A
  workspace's own wallpaper is keyed as `MONITOR:N` (see "Workspaces"),
  because ids change between sessions. hyprpaper outlives the shell, so every
  monitor is named once at start.
- The choice persists as `$XDG_STATE_HOME/quickshell/hyprpaper.conf`, which
  `source`s the repo's file and is started with `-c`. Don't reverse that: a
  hyprpaper config that sources a missing file fails to start. `fit_mode` is
  `cover` everywhere (`fill` stretches, and the IPC cannot express stretch).
- Blur size: `hyprctl eval` live, plus `blur.lua`, which `styles/layout.lua`
  applies. Glass tint: Adaptive mode raises `Colors.base.glassFloor` until
  muted text reaches WCAG AA over the brightest block that `BackdropProbe`
  measured, capped at `glassCeiling`. A `Canvas` reads image data in device
  pixels, so scale by the device pixel ratio. `AppTint` → `app-tint.sh`
  carries the tint to kitty (each instance's socket; only
  `set-background-opacity` is allowed without a password), Kvantum's SVG and
  the GTK stylesheets.

**Settings app.** A `FloatingWindow` built by a `LazyLoader` only while it is
open. `SettingsState` holds whether it is open and on which page, and any page
or tab name opens its place (`openPage keybinds`).
- Displays: `DisplayChange` applies rules through `displays.py` and
  `hyprctl eval` and reverts them unless Keep is pressed within 15 s. Kept
  rules (`desc:<description>`) go to `monitors.json`/`monitors.lua`, which
  `modules/monitors.lua` applies last. Hyprland's `desc:` matches by prefix.
- Bluetooth and Wi-Fi: start searching only once the adapter's `state` is on
  (`enabled` flips before the radio is up). Use `value: true` with
  `when: active && …`, so pages built unseen write nothing. Switch searching
  off in `Component.onDestruction`. Pairing that needs a PIN relies on
  blueman-applet as the BlueZ agent.
- Power: hypridle owns the idle times. `services/Idle` writes a state
  `hypridle.conf` (`$idleFromShell`, the times, then `source =` the repo's
  file). hyprlang's `if` tests for a non-empty value, so "never" is empty.
  hypridle reads its config only at start: `hypridle-restart.sh` restarts the
  instance with this `HYPRLAND_INSTANCE_SIGNATURE` only.
- Keybinds and the shortcuts overlay: both read `services/Keybinds`
  (`hyprctl binds -j`, and the text output for a keycode bind's key, which
  the JSON leaves out). A Lua bind reports only `__lua`, so every bind in
  `keybinds.lua` carries a `description`. Key labels come from xkbcommon
  (`keymap.py`), and a bind's key is looked up in the first layout, as
  Hyprland does.
- Startup: `modules/startup.lua` is plain data (`{ name, command, about }`,
  never `hl`), so the tab can read it with `lua`. `autostart.py` decides what
  XDG autostart runs the way systemd-xdg-autostart-generator does.
- Sound filters `Pipewire.nodes` by `PwNodeType`. An app's stream is
  `AudioOutStream`, and its `isSink` is true. Network details come from
  `nmcli` and are refreshed on `ip monitor address route`.

**Keyboard layouts.** Kept per machine in `keyboard.lua`, which
`modules/keybinds.lua` applies. Quickshell has no keyboard type, so
`KeyboardLayout` reads `hyprctl devices -j` on `activelayout` and on
`configreloaded`, ignoring `hl-virtual-keyboard*` devices. Switch with
`hyprctl switchxkblayout all <i>` and read back afterwards (Hyprland sends no
event when switching back to the previous layout).

**Notifications** (`NotificationService`, which owns
`org.freedesktop.Notifications`):
- Set `tracked = true` in the handler, or the notification is silently
  dropped. The object is destroyed once `closed` handlers return, so hold ids
  rather than objects.
- `expireTimeout` is in milliseconds. Only `-1` falls back to
  `Style.notifications.timeout`. Advertise only the capabilities that are
  actually rendered.
- The toast window's keyboard focus is `None`, and `OnDemand` only while the
  pointer is on it. A layer that maps with any other focus takes the keyboard
  and breaks open grabs.
- The centre opens in the toasts' column, and the toasts give way to it
  (`viewers`). Another notification daemon (dunst, swaync) is D-Bus activated
  and has to be masked, not disabled.

**Tray.** `nm-applet` and `blueman` icons are hidden by SNI id (`hiddenIds`),
but the processes are kept because they are the secret and pairing agents.
Icons are tinted with `MultiEffect` colorization. Don't add `saturation`: it
runs after colorization and undoes it. Menus are QML (`TrayMenu` +
`QsMenuOpener`), so there is no `UseQApplication`.

**Other surfaces**
- Media: MPRIS. Players without a title, and playerctld, are ignored. The
  last player to start playing is shown. `position` does not update by
  itself, so the open panel emits `positionChanged()` on a timer.
- Usage: the detailed reads run only while `SystemUsage.viewers > 0`. The
  temperature sensor is found by driver name, because hwmon numbers change
  between boots.
- The apps' calculator (`quickmenu/QuickMenuApps`): only arithmetic-looking
  input, or input after `=`, goes to `qalc -t`. Set the command where the
  process starts, not through a binding. `.config/qalculate/qalc.cfg` is in
  the repo.
- Shelf: plain files in the Nextcloud sync folder's `Shelf/`. Files are
  written as `.<name>.part` and renamed, and password-manager copies are
  refused.
- Lock: `WlSessionLock` with PAM `login`; `locked` lives in
  `PersistentProperties` so it survives a reload. The login screen's look
  only applies through `install-greeter.sh` (run through pkexec from the Lock
  Screen tab).
- Overview: `ScreencopyView` per toplevel (hidden workspaces included).
  Positions come from `lastIpcObject` after `Hyprland.refreshToplevels()`.
  Only the window on the focused screen takes the keyboard.
- Cursor finder: `modules/cursor.lua` detects the double Ctrl tap and posts
  `custom>>cursorfinder …` events. The shell reads them through
  `Hyprland.rawEvent`, takes no input, and hides on `configreloaded`.

**Quick menu** (`quickmenu/`, `services/QuickMenu`):
- Its keys are Lua binds (`modules/quickmenu.lua`), not `GlobalShortcut`s:
  press posts `custom>>quickmenu press X Y` with the pointer, release posts
  `quickmenu release`, which uses what the pointer moved to.
- Caps Lock is `kb_options = caps:none` plus a `code:66` bind. The Keyboard
  page's choice goes to `quickmenu.lua` and live through
  `hyprctl eval 'require("modules.quickmenu").useCapsLock(…)'`.
- Selection goes by direction from the centre. Once the pointer has been in
  a category's arc, another slot takes over only after `switchDelay`; while
  a list's panel is out, from the start.
- Items act through the services the tiles use. Screenshots and recording
  start `captureDelay` after the menu closes, or they capture it.
- An arc reads left to right in its listed order, which runs the other way
  round the ring on its left and lower side (`arcAngle()`, `arcIndex()`).
- A list item (the apps, the clipboard) shows its entries in a `RingList` out
  from its slot, as a category shows its arc; the pencil's options are a
  `RingPanel` too. The panel's body box overlaps the ring, so anything there
  that takes input is masked (`bodyMask`) or sits inside a row: a
  `containmentMask` on a `Flickable` does not keep its children's MouseAreas
  from taking clicks.
- The apps' list is the launcher. SUPER+R (`launcherToggle`) opens the menu
  centred with that list entered; letters type into a list only while it is
  entered, and are slot shortcuts otherwise.

**Workspaces.** Each monitor numbers its own: `modules/workspaces.lua` gives
each output name a block of 100 ids, recorded in
`$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/workspace-blocks.json`,
and the number shown is `id % 100`. Don't renumber with `change_id`: Quickshell
ignores that event. Hyprland creates a new monitor's first workspace in
another monitor's block, so `settle()` opens workspace 1 of the monitor's own
block. SUPER+CTRL+arrows need monitors whose edges touch.

**Themes.** `style/Theme.qml` watches the palette wallust renders, the
applied theme's name, and `appearance.json`. An ANSI slot is only trusted
when it is saturated (HSL saturation ≥ 0.25) and has contrast ≥ 2 against the
background; otherwise the default colour is used.

## Pitfalls

Each of these has already caused a bug.

**Hyprland and Wayland**
- A click outside a `HyprlandFocusGrab` only ends the grab; nothing under the
  pointer receives it.
- Moving a layer window to another screen drops its grab. Release the grab
  first, then move.
- Changing `WlrLayershell.keyboardFocus` on a mapped surface kills its grab.
  Keep it fixed (`OnDemand` is enough for text input). The toast window is the
  one exception.
- `OnDemand` alone gives no focus to an overlay opened from the bar. Use a
  `HyprlandFocusGrab` with a `FocusScope` around the content.
- A full-screen overlay's y=0 is already below the bar's exclusive zone.
  `Style.bar.sideGap` is where the bar's window starts, and `edgeGap` is where
  its frame appears to start; line popups up on `edgeGap`.
- `Hyprland.dispatch()` and `hyprctl dispatch` take Lua
  (`hl.dsp.exit()`), not hyprlang dispatchers.
- Saving several Hyprland modules at once races the autoreload. Run
  `hyprctl reload` afterwards.
- A nested Wayland output has no modes. Rules tested nested need an explicit
  `mode`.

**Quickshell**
- Service lists are `ObjectModel`s: they have no `count` and no `get(i)`
  (reading `.count` silently gives `undefined`). Use `model:` or `.values`.
- A delegate bound straight to an `ObjectModel` sees `modelData === null`
  before it is destroyed. Guard once on the delegate root. Delegates over
  `.values.filter(…)` are safe.
- `FileView` is asynchronous: setting `path` and reading in the same tick
  returns `""`. Use `reload()` + `text()` with `blockAllReads: true`, never
  from `onLoaded` (it recurses). `watchChanges` does nothing on sysfs.
  `writeAdapter()` is async, so debounce writes.
- A `Process` child survives a SIGTERM'd `qs`. Long-lived children run under
  `setpriv --pdeathsig TERM` (or `INT` for wf-recorder).
- Units: `UPowerDevice.percentage`, `WifiNetwork.signalStrength` and
  `PwNodeAudio.volume` are 0.0–1.0.
- Hot reload needs a content change (`touch` does nothing). If files are
  replaced underneath (a checkout), the watches can go stale.

**QML and Qt 6.11**
- A function whose result a binding reads, and which has typed parameters,
  needs a return type. Otherwise every call site logs an error. Untyped
  functions are fine.
- `state` and `top` are taken on every `Item`.
- A `Repeater` over a JS array gives each delegate a copy, so `===` and
  `includes()` fail. Compare by index or key.
- Qt 6.11's JS has no `Array.flat()`/`flatMap()`, and destructuring inside a
  loop reuses the previous element's values. Index arrays instead.
- A `Binding` destroyed with its object leaves its target set. For a service
  flag, count `viewers` in `onCompleted`/`onDestruction` instead.
- **Qt 6.11 can stop delivering the pointer** to a list that opens below its
  card if a later sibling lies inside the card. Keep such a row last, or move
  the sibling out (`PowerPage`). Debug with
  `QT_LOGGING_RULES="qt.quick.effectiveclip.debug=true"`.
- Add a `qmldir` line before the first file that uses the type. Saving only
  the `qmldir` does not trigger a reload.
- A polled value must not be what the UI reads back after a write. Set it
  optimistically, and hold off polling while the write settles
  (`Brightness.request()`).
- Private-use glyphs get lost in transit. That is why glyphs are escapes, and
  `scripts/pasted-glyphs.py` fails on a pasted one.

## Validating

```bash
scripts/check.sh          # format check, whitespace, qmllint (0 warnings), qmldirs,
                          # -popup names, glyphs, py/lua/sh syntax, both Hyprland
                          # configs, tests/
scripts/check.sh --fix    # format first
scripts/install-hooks.sh  # once per clone: pre-commit formats, pre-push checks
```

qmllint runs against a corrected copy of Quickshell's type information
(`scripts/quickshell-types.py`). It does not check writes inside handlers, or
anything reached through `var`, so the log has the last word:

```bash
qs log -r '*.debug=true;*.info=true' -- /run/user/$UID/quickshell/by-id/<id>/log.qslog
```

Count `Reloading configuration` lines to confirm that a reload happened. A
failed reload logs `Failed to load configuration` and keeps the old config
running.

Test anything risky outside the live session: a nested Hyprland with its own
`HOME`/`XDG_*`, or a panel rendered with `QT_QPA_PLATFORM=offscreen` and
`grabToImage()`. Never kill daemons by name: a nested session's daemons
share the names.

## Entry points

```bash
qs ipc call dropdown open calendar      # workspaces | calendar | quicksettings; openAt X Y
qs ipc call lock lock                   # no unlock IPC, by design
qs ipc call settings openPage keybinds  # toggle | open | close | openPage <name>
qs ipc call shortcuts toggle
qs ipc call quickmenu toggle            # apps | openAt X Y | close
hyprctl dispatch 'hl.dsp.global("quickshell:barExpand")'   # fire any GlobalShortcut
~/.config/wallust/apply.sh Nord         # recolours everything; see THEMING.md
```

Every shell shortcut is a `GlobalShortcut` bound in
`.config/hypr/modules/keybinds.lua`, except the quick menu's Lua binds, and
the three-finger swipe is an `hl.gesture` that calls `dropdown openAt`.

State files (`$XDG_STATE_HOME/quickshell/`): `appearance.json`,
`monitors.{json,lua}`, `keyboard.lua`, `quickmenu.lua`, `blur.lua`, `dropdowns.lua`,
`hypridle.conf`, `hyprpaper.conf`, `tint.conf`, `lockscreen.json`, and the
`statePath()` JSON files of individual services.
