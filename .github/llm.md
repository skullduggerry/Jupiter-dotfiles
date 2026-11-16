# Agent instructions

Hyprland desktop shell (QML, Quickshell 0.3.2) on Arch, plus Hyprland/wallust/app configs. Read `.github/PROJECT_STRUCTURE.md` before touching the shell, `.github/THEMING.md` before touching colours outside it, and the header comment of every file you change. `.config/*` is symlinked into `~/.config/`: edits are live, Quickshell and Hyprland hot-reload.

## Sources of truth, in order

1. This repo.
2. `/usr/lib/qt6/qml/Quickshell/**/*.qmltypes` (online docs may be newer than 0.3.2).
3. Qt 6 QML docs, Hyprland wiki (config is Lua; API in `/usr/share/hypr/stubs/hl.meta.lua`), ArchWiki.

Verify every type/property/signal/dispatcher in 1 or 2. Never copy from other dotfiles, forums or old Quickshell examples.

## Code

- Follow the closest existing pattern (bar and `panels/` are the reference). Stay in scope: no unrelated refactors, renames, reformatting or dependencies. Explain architectural changes first.
- Colours from `style/Colors.qml`, as formulas over `Colors.palette` (only `Colors.overlay` is literal); sizes, spacing, radii, fonts, durations from `style/Style.qml`. Reuse tokens; new ones named by role, not widget, in the inline-component groups.
- PascalCase files, camelCase ids/properties, typed properties (not `var`), relative imports (`import "../services"`), no unused imports. Every type in its folder's `qmldir` (add the line before using it).
- `pragma ComponentBehavior: Bound` where delegates read outer ids; delegates use `required property`, never `modelData`. Read `Loader` items typed (`(content.item as X)?.f()`).
- Declarative bindings; never assign over a binding. State lives with its owner; derive, don't duplicate.
- Quickshell services over processes/polling/`hyprctl`. Expensive work only while visible (`viewers` counts).
- Reuse `PanelFrame` (hosts add no margins), `PillGroup` (choice), `TextButton`, `SliderRow`/`VolumeRow`.
- Icons: Lucide, named in `icons/Icons.qml` as `"\u{…}"` escapes (never pasted), drawn with `Icon`, `Colors.icon.active`; colour only for attention.
- Outside text (apps, notifications, networks, devices, files, PAM): `textFormat: Text.PlainText`.
- Launch apps via `Session.app()`/`Session.entry()` (uwsm). Never patch `/usr/share`.
- Popups: open/close with `open`, never `visible`; layer namespace ends in `-popup` or Hyprland won't blur it.
- Panels report `implicitHeight` from intrinsic sizes, never their own `height` (binding loop).
- No fallbacks hiding missing APIs; handle genuinely optional state explicitly.
- Arch and NixOS both run these (Jupiter-installer sets up either). Find a system file the system's way (`XDG_DATA_DIRS`, PATH), not by an Arch path; a path that must stay fixed is linked by Jupiter-installer's `nixos/login.nix` (its `docs/nixos.md` lists them): add it there. PAM stacks name modules as Arch finds them, and NixOS gets them adapted there too.
- Comments: brief, *why* only. Long explanations go in `.github/`. No human docs unless asked.

## Pitfalls

**Hyprland**
- Focus grabs: click outside only ends the grab; moving a layer to another screen drops it (release first); changing `WlrLayershell.keyboardFocus` while mapped kills it. `OnDemand` alone doesn't focus an overlay opened from the bar: `HyprlandFocusGrab` + `FocusScope`.
- Full-screen overlay y=0 is already below the bar's exclusive zone. Align popups on `services/WindowGaps`.
- `Hyprland.dispatch()`/`hyprctl dispatch` take Lua (`hl.dsp.exit()`). Lens/blur works on whole layers only.
- `hl.timer` at config load crashes `--verify-config`: create on first use. Saving several modules at once races autoreload: `hyprctl reload` after. Nested outputs need an explicit `mode`.

**Quickshell**
- Service lists are `ObjectModel`s: no `count`/`get(i)` (silently `undefined`); use `model:` or `.values`. Their delegates see `modelData === null` before destruction.
- `FileView` is async: `reload()` + `text()` with `blockAllReads: true`, not from `onLoaded`. `watchChanges` doesn't work on sysfs. `writeAdapter()` is async: debounce.
- `Process` children survive a SIGTERM'd `qs`: wrap long-lived ones in `setpriv --pdeathsig TERM`.
- Hot reload needs a content change (`touch` doesn't; saving only `qmldir` doesn't). A new inline component in a loaded file breaks reloads until restart.

**QML/Qt 6.12**
- Functions with typed params read by bindings need a return type. `state` and `top` are taken on every `Item`. No `Array.flat()`/`flatMap()`. `Repeater` over a JS array copies elements: compare by index/key.
- A destroyed `Binding` leaves its target set: count `viewers` in `onCompleted`/`onDestruction`.
- Don't read back a polled value after writing: set optimistically, pause polling (`Brightness.request()`).
- `/usr/bin/qmlformat`/`qmllint` are Qt 5: use `/usr/lib/qt6/bin`.

**wallust 3.5.1**
- Always `-s` when testing (else escape codes hit every terminal): `wallust -d "$T" -q -s cs <scheme> -f pywal`. `theme X --preview` *applies*.
- Template errors are warnings with exit 0. No `rgba`, `alpha`, `desaturate`, `invert`, `mix` filters; `hexa` is broken.

## Done means

- `./check.sh` passes (`--fix` formats; `--help` for the rest). Fix what you broke; name pre-existing failures.
- New behaviour has a test in `../Jupiter-testing` (see its `.github/`): scripts → `dotfiles/test_<name>.py`, QML → `dotfiles/qml/<Name>Test.qml`, login/lock/Nextcloud/external text → `dotfiles/security/`.
- Whole diff read; shell log checked after reload. qmllint misses writes in handlers and anything via `var`; the log is final:
  `qs log -r '*.debug=true;*.info=true' -- /run/user/$UID/quickshell/by-id/<id>/log.qslog` (failure: `Failed to load configuration`, old config kept).
- Risky changes tested outside the live session (`QT_QPA_PLATFORM=offscreen` + `grabToImage()`, or a nested Hyprland with its own `HOME`/`XDG_*`, `render_unfocused = true`, stopped by PID). Never kill daemons by name.
- Report: what changed, why, how verified, what wasn't.
