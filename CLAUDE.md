# Jupiter-dotfiles: agent guide

A Hyprland desktop: a shell of its own in QML on Quickshell, plus the configs of the apps around it, coloured from one wallust theme. Quickshell 0.3.2, Hyprland 0.57.1 (Lua config), Qt 6.12, wallust 3.5.1; on Arch and NixOS, set up by Jupiter-installer. `.config/*` is symlinked into `~/.config/`: edits are live, and Quickshell and Hyprland hot-reload them.

## Git

Commit and push straight to `main`, here and in Jupiter-installer and Jupiter-testing: no branches or pull requests unless asked. CI (`.github/workflows/check.yml`) checks every push of this repo alone, on Arch and on NixOS; Jupiter-installer's checks the installer, and Jupiter-testing runs none.

## Sources of truth, in order

1. This repo: the header comment of every file you change, then this guide.
2. `/usr/lib/qt6/qml/Quickshell/**/*.qmltypes` (online docs may be newer than 0.3.2).
3. Qt 6 QML docs, the Hyprland wiki (API in `/usr/share/hypr/stubs/hl.meta.lua`), ArchWiki, wallust's docs.

Verify every type, property, signal and dispatcher in 1 or 2. Never copy from other dotfiles, forums or old Quickshell examples.

## Map

| Path | What |
| --- | --- |
| `.config/quickshell/` | the shell (below) |
| `.config/hypr/` | `hyprland.lua`, `modules/`, `styles/` (layer rules, blur, animations) |
| `.config/wallust/` | the theme ([Theming](#theming)) |
| `.config/kitty/`, `nvim/`, `Kvantum/`, `uwsm/`, … | the apps' own configs; `.config/.zshrc` → `~/.zshrc` |
| `etc/greetd/` | the login screen: a second Quickshell config, installed as a copy by `scripts/install-greeter.sh`, with `etc/pam.d/` |
| `etc/udev/`, `etc/pacman.d/`, `etc/systemd/user/` | installed as root by `scripts/install-system.sh` (on NixOS the installer's flake declares them) |
| `scripts/` | the system and greeter installers, generators |

Tests and linters live in `../Jupiter-testing`; package dependencies in Jupiter-installer's `arch/packages/core.txt`/`aur.txt` (Arch) and `nixos/` (NixOS).

```
.config/quickshell/
  shell.qml        builds every surface
  style/           Colors, Style (tokens), Theme, LockLook; copied to the greeter
  icons/           Icons (Lucide), Icon, BatteryIcon, RingIcon
  services/        singletons + helper scripts
  panels/          content shared by surfaces: PanelFrame, PillGroup, TextButton, SliderRow, …
  bar/             Bar (one PanelWindow per screen) → BarContent | SmallBarContent; widgets/
  dropdown/        three-finger-swipe overlay
  settings/        Settings app
  lock/ notifications/ osd/ overview/ shortcuts/ cursor/ quickmenu/   one surface each
```

- **Imports are a DAG**: `style/` and `services/` import nothing from the project; `panels/` only those two. `bar/` never imports `dropdown/` or `lock/`. Shared state lives in `services/`.
- **`style/` must run as the greeter** (no readable `$HOME`): read only, no process at construction, never `Quickshell.statePath()` (it creates the folder). Test with `HOME=/nonexistent`.
- `etc/greetd/monitors.lua` and `vconsole.lua` are links into `.config/hypr/modules/`; the installer copies them as files.
- IPC targets: `qs ipc show`.

## Where things go

| Adding | Goes |
| --- | --- |
| Colour / size, spacing, radius, font, duration | `style/Colors.qml` / `style/Style.qml`, in its feature group |
| Bar widget | `bar/widgets/` + `qmldir` + `BarContent.qml` (row or `BarDrawer`); `SmallBarContent.qml` if wanted on other screens |
| Widget dropdown | `WidgetPopup` (see `PowerWidget`) |
| Panel | `PanelFrame` in `panels/` |
| Quick-settings page | panel + `Component` in `QuickSettingsPanel` |
| Swipe zone | panel + zone in `DropdownState` + `Component` in `Dropdown.qml` |
| External data | `services/` singleton + helper via `Process` |
| Top-level surface | own folder + `qmldir`, like `shortcuts/` (overlay) or `settings/` (window) |
| Quick-menu item | `quickmenu/QuickMenuItems`; default slot in `services/QuickMenu` |
| Settings page/tab | `SettingsContent.pages` + `Component` in its `Loader` |
| Runs from login | service with `active`, bound from something always built (cf. `WallpaperService.active` in `SettingsApp.qml`) |
| Top-right surface | `PopupAreas.set()` so toasts move below |
| Keybind / shortcut | `.config/hypr/modules/keybinds.lua` (with a `description`), `GlobalShortcut` in the shell |
| Per-user/per-machine state | `Quickshell.statePath(…)` or `$XDG_STATE_HOME/quickshell/`, never the repo |
| A system file both systems need at a fixed path | Jupiter-installer's `nixos/login.nix` links it on NixOS (its `docs/nixos.md` lists them) |

## Code

- Follow the closest existing pattern (the bar and `panels/` are the reference). Stay in scope: no unrelated refactors, renames, reformatting or dependencies. Explain architectural changes first.
- Colours from `style/Colors.qml`, as formulas over `Colors.palette` (only `Colors.overlay` is literal); sizes, spacing, radii, fonts, durations from `style/Style.qml`. Reuse tokens; name new ones by role, not widget, in the inline-component groups.
- PascalCase files, camelCase ids/properties, typed properties (not `var`), relative imports (`import "../services"`), no unused imports. Every type in its folder's `qmldir` (add the line before using it).
- `pragma ComponentBehavior: Bound` where delegates read outer ids; delegates use `required property`, never `modelData`. Read `Loader` items typed (`(content.item as X)?.f()`).
- Declarative bindings; never assign over a binding. State lives with its owner; derive, don't duplicate.
- Quickshell services over processes, polling or `hyprctl`. Expensive work only while visible (`viewers` counts).
- Reuse `PanelFrame` (hosts add no margins), `PillGroup` (choice), `TextButton`, `SliderRow`/`VolumeRow`.
- Icons: Lucide, named in `icons/Icons.qml` as `"\u{…}"` escapes (never pasted), drawn with `Icon`, `Colors.icon.active`; colour only for attention.
- Text from outside (apps, notifications, networks, devices, files, PAM): `textFormat: Text.PlainText`.
- Launch apps via `Session.app()`/`Session.entry()` (uwsm). Never patch `/usr/share`.
- Popups: open and close with `open`, never `visible`; a layer namespace ends in `-popup` or Hyprland won't blur it.
- Panels report `implicitHeight` from intrinsic sizes, never their own `height` (binding loop).
- No fallbacks hiding missing APIs; handle genuinely optional state explicitly.
- Both systems run this code. Find a system file the system's way (`XDG_DATA_DIRS`, `PATH`), not by an Arch path. PAM stacks name modules as Arch finds them; Jupiter-installer's `nixos/login.nix` adapts them for NixOS, so change both.
- Comments: brief, *why* only. No human docs unless asked.

## Theming

One wallust theme colours the shell and the apps. `.config/wallust/apply.sh`'s header says how it runs, `wallust.toml` where each template renders, and each template's header what reads it and why.

- `templates/palette.jinja` mirrors `style/Colors.qml`'s formulas: change both together.
- `templates/Wallust.svg` is generated by `scripts/kvantum-template.py`: change roles in the script, not colours in the template.
- `/* glass */` lines (GTK) and `class="tint"` (Kvantum) are rewritten by `services/app-tint.sh`.
- On NixOS, Stylix themes what the templates don't reach (btop, mpv, Zed, the console, fontconfig), from `base16/<theme>.json`: `palette.jinja`'s `base16()` slots (nvim's too), rendered by `scripts/base16-schemes.py`. Jupiter-installer's `nixos/theme.nix` builds a home-manager specialisation of each, and `apply.sh` activates the theme's. Rerun the script after changing the slots or wallust; name a theme to pre-build it.

| Target | Picks up a new theme |
| --- | --- |
| Shell, blur, terminals, nvim | at once (terminals and nvim not with `--shell-only`) |
| GTK 3, portal dialogs, dark/light (portal `color-scheme`) | at once |
| Qt/KDE colours, GTK 4 colours, new kittys | next app start |
| Lock screen | at once, unless its Theme is Dark |
| Login screen | Apply on the Lock Screen tab (`install-greeter.sh`) |
| btop, mpv, Zed (NixOS) | next app start; a theme without `base16/` gets the default theme's |

## Pitfalls

**Hyprland**
- Focus grabs: a click outside only ends the grab; moving a layer to another screen drops it (release first); changing `WlrLayershell.keyboardFocus` while mapped kills it. `OnDemand` alone doesn't focus an overlay opened from the bar: `HyprlandFocusGrab` + `FocusScope`.
- A full-screen overlay's y=0 is already below the bar's exclusive zone. Align popups on `services/WindowGaps`.
- `Hyprland.dispatch()`/`hyprctl dispatch` take Lua (`hl.dsp.exit()`). Lens and blur work on whole layers only.
- `hl.timer` at config load crashes `--verify-config`: create it on first use. Saving several modules at once races autoreload: `hyprctl reload` after. Nested outputs need an explicit `mode`.

**Quickshell**
- Service lists are `ObjectModel`s: no `count`/`get(i)` (silently `undefined`); use `model:` or `.values`. Their delegates see `modelData === null` before destruction.
- `FileView` is async: `reload()` + `text()` with `blockAllReads: true`, not from `onLoaded`. `watchChanges` doesn't work on sysfs. `writeAdapter()` is async: debounce.
- `Process` children survive a SIGTERM'd `qs`: wrap long-lived ones in `setpriv --pdeathsig TERM`.
- Hot reload needs a content change (`touch` doesn't; saving only `qmldir` doesn't). A new inline component in a loaded file breaks reloads until restart.

**QML / Qt 6.12**
- Functions with typed parameters read by bindings need a return type. `state` and `top` are taken on every `Item`. No `Array.flat()`/`flatMap()`. `Repeater` over a JS array copies elements: compare by index or key.
- A destroyed `Binding` leaves its target set: count `viewers` in `onCompleted`/`onDestruction`.
- Don't read back a polled value after writing: set it optimistically and pause polling (`Brightness.request()`).
- On Arch, `/usr/bin/qmlformat` and `qmllint` are Qt 5: use `/usr/lib/qt6/bin`.

**wallust 3.5.1**
- Always `-s` when testing (else escape codes hit every terminal): `wallust -d "$T" -q -s cs <scheme> -f pywal`. `theme X --preview` *applies*.
- Template errors are warnings with exit 0. No `rgba`, `alpha`, `desaturate`, `invert`, `mix` filters; `hexa` is broken.

## Done means

- `./check.sh` passes (`--fix` formats; `--help` for the rest). Fix what you broke; name pre-existing failures.
- New behaviour has a test in `../Jupiter-testing` (its `AGENTS.md`): a script → `dotfiles/test_<name>.py`, QML → `dotfiles/qml/<Name>Test.qml`, login, lock, Nextcloud or text from outside → `dotfiles/security/`.
- The whole diff read; the shell's log checked after reload. qmllint misses writes in handlers and anything through `var`; the log is final: `qs log -r '*.debug=true;*.info=true' -- /run/user/$UID/quickshell/by-id/<id>/log.qslog` (failure: `Failed to load configuration`, the old config kept).
- Risky changes tried outside the live session (`QT_QPA_PLATFORM=offscreen` + `grabToImage()`, or a nested Hyprland with its own `HOME`/`XDG_*`, `render_unfocused = true`, stopped by PID). Never kill daemons by name.
- Report what changed, why, how it was verified, and what wasn't.
