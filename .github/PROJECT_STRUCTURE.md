# Project structure

Repo map and rules the code doesn't show. Coding rules: `.github/llm.md`. App colours: `.github/THEMING.md`.

Quickshell 0.3.2, Hyprland 0.57.1 (Lua config), Qt 6.12, Arch.

## Repo

| Path | What |
| --- | --- |
| `.config/` | symlinked into `~/.config/` (installer phase 4), `.zshrc` → `~/.zshrc` |
| `.config/quickshell/` | the shell |
| `.config/hypr/` | `hyprland.lua`, `modules/`, `styles/` (layer rules, blur, animations) |
| `.config/wallust/` | theming (THEMING.md) |
| `.config/claude-desktop-flags.conf` | makes Claude Desktop keep secrets in gnome-keyring |
| `etc/greetd/` | login screen: a second Quickshell config over `Quickshell.Services.Greetd` (`greeter-env.py` lists users/sessions). Installed as a copy by `scripts/install-greeter.sh` with `etc/pam.d/` |
| `etc/udev/`, `etc/pacman.d/`, `etc/systemd/user/` | installed as root by `scripts/install-system.sh`: tablet pad udev rule, pacman hook running `scripts/uwsm-desktop-entries.py`, `ConditionUser=!greeter` drop-in, root's copy of `install-greeter.sh` + greetd config + `finger-asked` + `disk-encrypted` + PAM stacks in `/usr/local/lib/jupiter/greeter` |
| `scripts/` | system/greeter installers, generators (`kvantum-template.py`) |
| `pyproject.toml`, `.luarc.json`, `.editorconfig` | linter/formatter settings (no Python package) |

Checks and tests live in `../Jupiter-testing`. Package deps go in Jupiter-installer's `packages/core.txt`/`aur.txt` (check tools: `pacman.txt`).

## The shell

```
shell.qml        builds every surface
style/           Colors, Style (tokens), Theme (palette + appearance.json), LockLook; copied to the greeter
icons/           Icons (Lucide names, lucide.ttf), Icon, BatteryIcon, RingIcon
services/        singletons + helper scripts (*.py, *.sh)
panels/          content shared by surfaces: PanelFrame, PopupFrame, PillGroup, TextButton, SliderRow, …
bar/             Bar (PanelWindow per screen) → BarContent | SmallBarContent; BarDrawer; BackdropProbe; widgets/
dropdown/        three-finger-swipe overlay
settings/        SettingsApp (window, IPC) + SettingsContent + pages
lock/ notifications/ osd/ overview/ shortcuts/ cursor/ quickmenu/   one surface each
```

- **Imports are a DAG**: `style/`, `services/` import nothing from the project; `panels/` only those two. `bar/` never imports `dropdown/` or `lock/`. Shared state lives in `services/` (`DropdownState`, `LockService`, `SettingsState`).
- **`style/` must run as the greeter** (no readable `$HOME`): read only, no process at construction, never `Quickshell.statePath()` (it creates the dir). Test with `HOME=/nonexistent`. Desktop data comes from copies named in `LOCKSCREEN_STYLE`/`LOCKSCREEN_THEME`, never written back.
- `etc/greetd/monitors.lua`, `vconsole.lua` are symlinks into `.config/hypr/modules/`; the installer copies them as files.

## Conventions

- Format: Qt 6 `qmlformat`, ruff, shfmt, stylua (`./check.sh --fix`). `/usr/bin/qmlformat`/`qmllint` are Qt 5: use `/usr/lib/qt6/bin`. No `--normalize`.
- Every folder's `qmldir` lists each type.
- `pragma ComponentBehavior: Bound` where delegates read outer ids. Delegates use `required property`, never `modelData`. Read `Loader` items typed (`(content.item as X)?.f()`).
- `Style`/`Colors` groups are inline components (`component BarStyle: QtObject {…}`).
- **Colours are formulas over `Colors.palette`** (bg, fg, 6 ANSI). Only `Colors.overlay` is literal.
- **Icons**: Lucide only, named in `icons/Icons.qml` as `"\u{E059}"` escapes (never pasted), drawn with `Icon` (other `Text`: `font.family: Icons.font`). Always `Colors.icon.active`; colour only for attention.
- **Panels are `PanelFrame`s** (own padding, header, separator); hosts add no margins.
- Choice → `PillGroup`; clickable word/glyph → `TextButton`; level → `SliderRow` (`VolumeRow` for PipeWire).
- **Outside text** (apps, notifications, networks, devices, files, PAM) → `textFormat: Text.PlainText`. Notification bodies: `StyledText` via `NotificationService.withoutImages()` (strips `<img>` repeatedly).
- Launch via `Session.app()`/`Session.entry()`, log out via `Session.logout()` (uwsm). pyxdg rejects `Implements=`/reverse-DNS groups; the pacman hook writes cleaned copies to `/usr/local/share/applications`. Never patch `/usr/share`.
- Per-user and per-machine state: `Quickshell.statePath(…)` or `$XDG_STATE_HOME/quickshell/`, never the repo.

## Where things go

| Adding | Goes |
| --- | --- |
| Colour | `style/Colors.qml`, feature group, from palette |
| Size/spacing/radius/font/duration | `style/Style.qml`, feature group |
| Bar widget | `bar/widgets/` + `qmldir` + `BarContent.qml` (row or `BarDrawer`); `SmallBarContent.qml` if wanted on other screens. Needs monitor → `required property ShellScreen screen` |
| Widget dropdown | `WidgetPopup` with `anchorItem`, `namespaceSuffix` ending `-popup`, content as children (see `PowerWidget`) |
| Panel | `PanelFrame` in `panels/` setting `implicitHeight` |
| Quick-settings page | panel + `page*` index + `Component` in `QuickSettingsPanel` |
| Swipe zone | panel + zone in `DropdownState` and `step()` + `Component` in `Dropdown.qml` |
| External data | `services/` singleton + helper via `Process` |
| Top-level surface | own folder + `qmldir`, like `shortcuts/` (overlay) or `settings/` (window) |
| Quick-menu item | `quickmenu/QuickMenuItems`; default slot in `services/QuickMenu` |
| Settings page/tab | entry in `SettingsContent.pages` + `Component` in its `Loader`. Use `ScrollPage`, `PanelCard`, `FormCard`/`FormRow`, `Card` |
| Runs from login | service with `active`, bound from something always built (cf. `WallpaperService.active` in `SettingsApp.qml`) |
| Top-right surface | `PopupAreas.set()` so toasts move below |
| Non-dropdown `-popup` | `qs-not-dropdowns` rule in `.config/hypr/styles/layout.lua` |
| Helper script | Jupiter-testing `dotfiles/test_<name>.py` (untested helpers fail checks) |
| QML logic | Jupiter-testing `dotfiles/qml/<Name>Test.qml` (`TestCase`, `test_*`) |
| Login/lock/secrets/outside text | Jupiter-testing `dotfiles/security/` |

## Surfaces and services

**Popups.** Toggle `WidgetPopup`/`Dropdown` with `open`, never `visible` (closing animates; mask empty, grab released). Blur is Hyprland's layer rule `^quickshell:.*-popup$`: a namespace without `-popup` silently renders flat.

**Swoosh** (`Theme.swoosh`): disables fade via layer rule `qs-dropdown-swoosh` (`hyprctl eval`, persisted in `dropdowns.lua`); `qs-not-dropdowns` after it re-enables fade for OSD/toasts (later rule wins).

**Panel contract is `implicitHeight` only**, from intrinsic sizes, never own `height` (loop). Hosts `Math.floor` it.

**Quick-settings pager** (`QuickPager`, dropdown right zone): wrapping `PathView`, path must be `pathItemCount` page-widths long. Paged by horizontal wheel on the backdrop (`Style.pager.swipeStep`/`swipeRepeat`/`swipeIdle`). Any `Flickable` in a page needs `flickableDirection: Flickable.VerticalFlick`. Dismiss waits `Style.popup.dismissDelay` (touchpad swipe clicks first). All pages built up front: gate scanning/search on current page.

**Arrow keys** step zones/pages (`DropdownState.step()`, `QuickSettingsPanel.step(direction, wrap)`) unless `Window.activeFocusItem instanceof TextInput`.

**OSD** (`osd/`): owns media keys (`GlobalShortcut`s bound with `hl.dsp.global`). No input (empty mask, focus `None`). `OsdState.viewers` keeps it from showing with quick settings; a dropdown opened within `timeout` of a key starts on that key's page.

**Bars.** `BarLayout.main` (Settings → Displays, by port in `bar.json`; else top-left screen) gets the full bar, others the small pill. One `PanelWindow` per screen, content swapped by `Loader` (Caffeine's `IdleInhibitor` needs a pre-mapped surface). Inhibitor binds `bar.caffeine`, not `QuickToggles` (loop). Edges align with `general:gaps_out` (`services/WindowGaps`, read at start and on `configreloaded`); reserves down to `Style.bar.depth`. Popups open level with window tops. Small bars may float (`exclusiveZone: 0`); `Dropdown`/`WidgetPopup` clear them; popups centre under the pill when `screen !== BarLayout.main`. Drawer is anchored, not in a `Row` (Row jumps at width 0); `clip` blocks hidden clicks.

**Power button**: `PowerButton` holds `systemd-inhibit --what=handle-power-key` while unlocked (released on lock, retaken 5 s after); `XF86PowerOff` opens the power menu.

**Quick toggles** (`QuickToggles`, `panels/TogglesPanel`): Night Light = owned `hyprsunset` process (one CTM client; a second exits 1). Screen Record = `wf-recorder`, stopped with SIGINT. Clipboard = two `wl-paste --watch cliphist store`. Airplane = NetworkManager + BlueZ, not rfkill. Persisted in `quick-toggles.json`; tiles show real process state. Bars construct `QuickToggles`, which restores Night Light at login.

**Calendar** (`CalendarService` + `nextcloud-calendar.py`, CalDAV):
- Never blocks UI: range padded by `prefetchDays`, snapped to months, cached in `calendar-cache.json`, refetched past `staleAfter`, debounced, ≤4 parallel REPORTs.
- Server/login in `nextcloud.json`, passed via `Process.environment`. App password only in keyring (`secret-tool`), never QML/state/argv. `https://` only (except loopback), also for Login Flow v2 (`nextcloud-login.py`); redirects only to https (`SecureRedirects`), calendar only same-server (`SameServer`, `resolve()`; urllib keeps Authorization across redirects). Tasks completed only at the server's calendar URLs (`task_url()`). Home found via `current-user-principal`. One unreadable object/calendar fails alone.
- `calendar.json`: `weekStart` (-1 = locale), `shownWeeks`. Grid via `gridStart()`/`weekCount()`/`page()`.
- `calendar-color` is `#rrggbbaa`: cut to `#rrggbb` (QML reads 8 digits as ARGB). Skip nested components. Tasks = VTODOs without `COMPLETED`.
- `complete()` → `--complete HREF`: hides at once, writes serialised, refetch restores failures (`completeProblem`); `fetchHides` covers stale fetches. GET + PUT with `If-Match`; path must be under `/remote.php/dav/calendars/`.
- Helper always answers one JSON object; malformed input is refused before writing. `INTERVAL=0` refused by hand (dateutil hangs).
- Recurring task done: `RECURRENCE-ID` record in the task's own object (separate object → 409 `no-uid-conflict`), task advanced via dateutil `rrule` (`COUNT` lowered) or finished.

**Wallpaper** (`WallpaperService`, hyprpaper 0.8.5 via `hyprctl hyprpaper`):
- Library `~/Wallpapers`, subfolders = tabs. Per-workspace key `MONITOR:N` (see Workspaces). Every monitor named once at start.
- State `$XDG_STATE_HOME/quickshell/hyprpaper.conf` `source`s the repo file, started with `-c`. Don't reverse (missing source = no start).
- One `fit_mode` (`cover`/`contain`/`tile`) in `wallpaper.json`; changing renames all monitors. No stretch (hyprctl `stretch` → `cover` in 0.8.5).
- Blur variants (`decoration:blur:variant`) in `style/BlurVariants`. `services/HyprBlur` (fed colours by `SettingsApp.qml`) sends *every* option via `hyprctl eval`, saved to `blur.lua` (applied by `styles/layout.lua`). Colours as `rgba(rrggbbaa)`. Out-of-range values give a red banner at login; `test_blur_options.py` verifies all defaults/bounds with `Hyprland --verify-config` (fluid jar weight min 0.2). Solid → `Colors.base.variant` Kawase.
- Glass follows variant (`Colors.base`). Clear variants (acrylic, prism): BackdropProbe measures the backdrop. Tint ≥10% (`Colors.tintLeast`) pairs with `ignore_alpha` 0.05 in `styles/layout.lua`; change together. Acrylic: faint `edge` + `GlassHighlight` under content.
- Acrylic `refraction` ≤12 (past 10 px `gaps_out` it samples the neighbour window); `effective()` clamps. Tint uses lighter colour (`Colors.base.glassTint`).
- **Hyprland 0.57 lenses whole layers only.** Layer-filling surfaces (bar, lone toast, ChoiceField list) use `GlassHighlight { lensed: true }`; full-screen-layer panels get a drawn rim (`Style.blur.rimBand` bands, one slope, no inner line). Drop the drawn rim once a layer rule can shape the lens.
- Adaptive tint raises `Colors.base.glassFloor` until muted text hits WCAG AA over BackdropProbe's brightest block, capped at `glassCeiling`; beyond that `Colors.text.muted` moves toward text (`mutedOver()`). `glassOver()` uses design muted, not raised. `Canvas` image data is device pixels. `AppTint` → `app-tint.sh` → kitty (`set-background-opacity`), Kvantum SVG, GTK CSS.

**Settings app.** `FloatingWindow` in a `LazyLoader`, `surfaceFormat.opaque: false` (alpha fixed at creation). `SettingsState` holds open/page; `openPage <name>` accepts any page or tab name.
- Hyprland may tile it below `minimumSize`: pill rows wrap (`PillGroup` is a `Flow`), two-sided rows stack. `SettingsLayoutTest.qml` catches overflow.
- `ChoiceField` list is a `PopupWindow` (xdg_popup, blur via `blur.popups`); a full-window `MouseArea` eats in-window clicks while open.
- Displays: `DisplayChange` applies via `displays.py` + `hyprctl eval`, reverts unless Keep within 15 s. Kept rules (`desc:` prefix match) → `monitors.json`/`monitors.lua`, applied last by `modules/monitors.lua`. Monitors must touch, sharing ≥¼ of the shorter edge, no overlap (`fit()`, `settle()`).
- Bluetooth/Wi-Fi: scan only once adapter `state` is on (`enabled` flips early). `value: true` with `when: active && …`; stop scanning in `Component.onDestruction`. PIN pairing uses blueman-applet.
- Power: hypridle owns idle times; `services/Idle` writes state `hypridle.conf` (`$idleFromShell`, times, `source =` repo file). "Never" = empty. Restart via `hypridle-restart.sh` (this instance only).
- Keybinds/overlay read `services/Keybinds` (`hyprctl binds -j`; keycode binds show `code:66`). Lua binds report `__lua`, so every bind in `keybinds.lua` needs a `description`. Labels via xkbcommon (`keymap.py`), first layout.
- `modules/startup.lua` is plain data (`{ name, command, slice, about }`, no `hl`). `autostart.py` mirrors systemd-xdg-autostart-generator.
- Sound: filter `Pipewire.nodes` by `PwNodeType`; app streams are `AudioOutStream` with `isSink` true. Network via `nmcli`, refreshed on `ip monitor address route`.

**Keyboard layouts**: `keyboard.lua`, applied by `modules/keybinds.lua`. `KeyboardLayout` reads `hyprctl devices -j` on `activelayout`/`configreloaded`, ignoring `hl-virtual-keyboard*`. Switch with `hyprctl switchxkblayout all <i>` then read back (no event when switching back).

**Mouse/touchpad** (`Pointer`, `modules/pointer.lua`): `pointer.lua` at start, live via `require("modules.pointer").use({…})`. `input.sensitivity`, `input.scroll_factor`, `input.touchpad.scroll_factor`; per-touchpad sensitivity via `hl.device` by `hyprctl devices -j` name.

**Tablet** (`Tablet`, `modules/tablet.lua`):
- Via `input.tablet`/`input.tablettool`, not `hl.device`. `tablet.lua` at start, live via `require("modules.tablet").use({…})`. SUPER+T / SUPER+SHIFT+T map to focused screen/window (window tracked by 200 ms timer).
- Keep proportions: `active_area_*` in mm from udev `ID_INPUT_WIDTH_MM`/`HEIGHT_MM` (`tablet.py`). Always set an area (0x0 keeps the old one).
- `hl.timer` at config load crashes `--verify-config`: create on first use (as `cursor.lua`).
- Pad buttons: `tablet.py pad` grabs the event node (`etc/udev/rules.d/70-tablet-pad.rules`), presses run `require("modules.tablet").press(mods, key)`. No-op while locked.
- Pad shortcuts: `keybinds.lua` binds through `tablet.bind`; `press()` runs that bind, else sends key down+up to the focused window.
- `ShortcutField` records via unshifted keysym (`Keymap.symOf`) in submap `tablet-record` (only bind: Escape). `Keybinds` skips other submaps.

**Notifications** (`NotificationService`):
- Set `tracked = true` or it's dropped. Object dies after `closed` handlers: keep ids.
- `expireTimeout` is ms; only `-1` uses `Style.notifications.timeout`. Advertise only rendered capabilities.
- Toast focus `None`, `OnDemand` only while hovered (other focus breaks grabs).
- Centre opens in the toasts' column (`viewers`). Other daemons (dunst, swaync) must be masked.

**Tray.** `nm-applet`/`blueman` hidden by SNI id (`hiddenIds`) but kept running (agents). Tint with `MultiEffect` colorization, no `saturation`. Menus are QML (`TrayMenu` + `QsMenuOpener`), no `UseQApplication`.

**Other surfaces**
- Media: MPRIS, ignoring untitled players and playerctld; last to play wins. Open panel emits `positionChanged()` on a timer.
- Battery: `UPower.displayDevice` exists on desktops (0%, Unknown); without a battery the first page is "Power" (`BatteryPanel.battery`).
- Usage: detailed reads only while `SystemUsage.viewers > 0`. Temperature sensor by driver name.
- Brightness: polled only while `Brightness.viewers > 0`, re-read before key changes; max read once.
- Calculator (`quickmenu/QuickMenuApps`): arithmetic-looking or `=`-prefixed input → `qalc -t`, command set at process start. `qalc.cfg` has `save_config=0`.
- Shelf: Nextcloud `Shelf/`; write `.<name>.part` then rename; password-manager copies refused.
- **Lock**: `WlSessionLock` + PAM `login`. `locked` in `PersistentProperties` and in `quickshell-locked` beside Hyprland's socket (relocks after crash). hypridle `inhibit_sleep = 3`. Extra PAM questions answered from the field.
  - Fingerprint via `pam/fingerprint.conf`, separate from the password stack. One try per attempt; `LockService` falls back to password after 3 misses.
  - Greeter: one greetd conversation. With a reader, it answers the password prompt empty on open (and on Enter with empty field); `etc/pam.d/greetd` routes only the empty answer to pam_fprintd (`etc/greetd/finger-asked`). Typed password queued during the ≤5 s scan (`queued`). Three single-try pam_fprintd lines; pam_faillock counts misses in `/var/lib/faillock-finger` (5 in 15 min → reader off 10 min; password or a match clears; timeouts uncounted).
  - Keyring: unencrypted on encrypted disks (installer phase 4), so a finger opens it; there `etc/greetd/disk-encrypted` keeps the typed password from gnome-keyring. On unencrypted disks a finger login leaves it locked.
  - Greeter look applies only via `install-greeter.sh`: the Lock Screen tab runs root's copy (`/usr/local/lib/jupiter/greeter`) via pkexec with `--from` the clone; root reads the clone/owner state only as the owner.
- Lock/login theme = desktop's unless the Lock Screen tab's Theme is Dark (`LockLook.followTheme`, `Colors.lock`).
- Overview: `ScreencopyView` per toplevel; positions from `lastIpcObject` after `Hyprland.refreshToplevels()`. Only focused screen takes keys.
- Cursor finder: `modules/cursor.lua` posts `custom>>cursorfinder …`; read via `Hyprland.rawEvent`, no input, hides on `configreloaded`.

**Quick menu** (`quickmenu/`, `services/QuickMenu`):
- Lua binds (`modules/quickmenu.lua`), not `GlobalShortcut`s: `custom>>quickmenu press X Y` / `quickmenu release`.
- Caps Lock: `kb_options = caps:none` + `code:66` bind; toggled live via `hyprctl eval 'require("modules.quickmenu").useCapsLock(…)'`.
- Looks (`QuickMenu.look`): Halo, Orbit, Auto (Orbit over blur, Halo over Solid), resolved in `QuickMenuContent` (`orbit`) since `services/` can't read `Theme`. Hit-testing/keys/motion shared.
- Selection by direction; slot switch after `switchDelay` once in an arc.
- Items act via the tiles' services. Captures start `captureDelay` after close.
- Arc order left→right (`arcAngle()`, `arcIndex()`). Items never move: unavailable → greyed (`disabled`); `available` drops only hardware the machine lacks. Paired devices fill to `maxItems`.
- Labels `Colors.text.base`, never muted; shrink via `room()`; Halo places label above/below glyph (`labelAbove()`), labels hideable (`QuickMenu.labels`).
- `KeyHint` letters appear after `keyDelay` or a key press.
- Lists (apps, clipboard, notifications): `RingList` of `RingRow`s from `arcInner`, fading to `Colors.fadeFloor`. Rows have no `MouseArea` (menu does `hit()`, `rowAt()`). Pencil options: `RingPanel`.
- Wheel over a list slot scrolls it (`scrollList()`, `wheelSlot`); over the list turns it a row per notch; keys centre via `show()`.
- Apps list over `services/Apps`, which drops entries whose program is missing (`TryExec` is ignored). SUPER+R (`launcherToggle`) opens it; letters type only inside an entered list.

**Workspaces.** `modules/workspaces.lua` gives each output a block of 100 ids (`$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/workspace-blocks.json`); shown number is `id % 100`. Special workspaces have no id in 0.57 Lua/JSON. Never `change_id` (Quickshell ignores it). `settle()` opens the monitor's own workspace 1. SUPER+CTRL+arrows need touching monitors.

**Themes.** `style/Theme.qml` watches the wallust palette, theme name and `appearance.json`. ANSI slots used only if HSL saturation ≥ 0.25 and contrast ≥ 2 vs background, else defaults.

## Pitfalls

**Hyprland/Wayland**
- Click outside a `HyprlandFocusGrab` only ends the grab.
- Moving a layer to another screen drops its grab: release first.
- Changing `WlrLayershell.keyboardFocus` while mapped kills the grab (toasts excepted).
- `OnDemand` alone doesn't focus an overlay opened from the bar: use `HyprlandFocusGrab` + `FocusScope`.
- Full-screen overlay y=0 is already below the bar's exclusive zone. Align popups on `WindowGaps`.
- `Hyprland.dispatch()`/`hyprctl dispatch` take Lua (`hl.dsp.exit()`).
- Saving several modules at once races autoreload: `hyprctl reload` after.
- Nested outputs have no modes: rules need explicit `mode`.

**Quickshell**
- Service lists are `ObjectModel`s: no `count`/`get(i)` (silently `undefined`). Use `model:` or `.values`.
- Delegates on an `ObjectModel` see `modelData === null` before destruction: guard on root. `.values.filter(…)` is safe.
- `FileView` is async: use `reload()` + `text()` with `blockAllReads: true`, never from `onLoaded`. `watchChanges` doesn't work on sysfs. `writeAdapter()` is async: debounce.
- `Process` children survive SIGTERM'd `qs`: wrap long-lived ones in `setpriv --pdeathsig TERM` (`INT` for wf-recorder).
- `UPowerDevice.percentage`, `WifiNetwork.signalStrength`, `PwNodeAudio.volume` are 0–1.
- Hot reload needs a content change (`touch` doesn't); checkouts can stale watches.
- A new inline component in a loaded file breaks reloads (`X is not a type`) until restart. New properties are fine.

**QML/Qt 6.12**
- Functions with typed params read by bindings need a return type.
- `state` and `top` are taken on every `Item`.
- `Repeater` over a JS array copies elements: compare by index/key.
- No `Array.flat()`/`flatMap()`.
- A destroyed `Binding` leaves its target set: count `viewers` in `onCompleted`/`onDestruction`.
- A list opening below its card can lose the pointer if a later sibling lies inside the card: keep such rows last (`PowerPage`). Debug: `QT_LOGGING_RULES="qt.quick.effectiveclip.debug=true"`.
- Add the `qmldir` line before using the type; saving only `qmldir` doesn't reload.
- Don't read back a polled value after writing: set optimistically, pause polling (`Brightness.request()`).
- Private-use glyphs get lost: escapes only (`scripts/pasted-glyphs.py` enforces).

## Validating

```bash
./check.sh                  # format, qmllint (0 warnings), qmldirs, -popup names, glyphs, ruff+mypy, lua, shellcheck, json/toml, Hyprland configs, tests
./check.sh --fix            # format + safe fixes first
./check.sh lint | test      # one half
./check.sh test --security
../Jupiter-testing/scripts/install-hooks.sh
# in ../Jupiter-testing:
python3 -m harness.qml dotfiles/qml/ColorsTest.qml
python3 -m unittest dotfiles.test_shelf
```

- `check.sh` delegates to Jupiter-testing (next to this repo or `$JUPITER_TESTING`, cloned if missing). Every helper must be run by a test (Python coverage floor in its `scripts/test.sh`).
- lua-language-server uses Hyprland stubs (`.luarc.json`); `---@diagnostic` marks where stubs are too narrow.
- QML tests run offscreen with no session; `ignoreWarning()` for expected warnings.
- qmllint misses writes in handlers and anything via `var`; the log is final:

```bash
qs log -r '*.debug=true;*.info=true' -- /run/user/$UID/quickshell/by-id/<id>/log.qslog
```

Count `Reloading configuration` lines; failure logs `Failed to load configuration` and keeps the old config.

Test risky changes outside the live session (nested Hyprland with own `HOME`/`XDG_*`, or `QT_QPA_PLATFORM=offscreen` + `grabToImage()`). Never kill daemons by name.

**Nested session** (for blur), from temp dir `$T`:

```bash
run=$XDG_RUNTIME_DIR/jn     # short: socket path ≤108 bytes
mkdir -m 700 -p "$run" "$T/home/.config/hypr"
ln -s ~/Jupiter-dotfiles/.config/quickshell "$T/home/.config/quickshell"
# hyprland.lua: package.path = "<repo>/.config/hypr/?.lua;" .. package.path, require only what's tested (not modules.start)
nested="env -u HYPRLAND_INSTANCE_SIGNATURE -u DBUS_SESSION_BUS_ADDRESS
  HOME=$T/home XDG_CONFIG_HOME=$T/home/.config XDG_STATE_HOME=$T/home/.local/state
  XDG_CACHE_HOME=$T/home/.cache XDG_RUNTIME_DIR=$run
  WAYLAND_DISPLAY=$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
hyprctl eval "hl.exec_cmd([[$nested Hyprland -c $T/home/.config/hypr/hyprland.lua]],
  { workspace = 'special:nest silent', render_unfocused = true })"
# then with nested XDG_RUNTIME_DIR, HYPRLAND_INSTANCE_SIGNATURE (ls $run/hypr), WAYLAND_DISPLAY (ls $run): qs -p …, hyprctl eval …, grim
```

- `render_unfocused` is required (else `grim` hangs).
- Headless outputs fail nested on NVIDIA: use the window's output.
- Monitor rules need explicit `mode`; scale starts at the parent's.
- Stop by PID (`pgrep -xf "Hyprland -c $T/…"`).

## Entry points

```bash
qs ipc call dropdown open calendar      # workspaces | calendar | quicksettings; openAt X Y
qs ipc call lock lock                   # no unlock IPC
qs ipc call settings openPage keybinds  # toggle | open | close | openPage <name>
qs ipc call shortcuts toggle
qs ipc call quickmenu toggle            # apps | openAt X Y | close
hyprctl dispatch 'hl.dsp.global("quickshell:barExpand")'
~/.config/wallust/apply.sh Nord
```

Shortcuts are `GlobalShortcut`s bound in `.config/hypr/modules/keybinds.lua` (except the quick menu's Lua binds); three-finger swipe is an `hl.gesture` → `dropdown openAt`.

State (`$XDG_STATE_HOME/quickshell/`): `appearance.json`, `monitors.{json,lua}`, `keyboard.lua`, `quickmenu.lua`, `blur.lua`, `dropdowns.lua`, `tablet.lua`, `pointer.lua`, `hypridle.conf`, `hyprpaper.conf`, `tint.conf`, `lockscreen.json`, plus services' `statePath()` JSON.
