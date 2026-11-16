# Project structure

Repo map and the rules no single file shows. Each service, surface and helper explains itself in its header comment: read that first. Coding rules and pitfalls: `.github/llm.md`. App colours: `.github/THEMING.md`.

Quickshell 0.3.2, Hyprland 0.57.1 (Lua config), Qt 6.12, Arch.

## Repo

| Path | What |
| --- | --- |
| `.config/` | symlinked into `~/.config/` (installer phase 4), `.zshrc` → `~/.zshrc` |
| `.config/quickshell/` | the shell |
| `.config/hypr/` | `hyprland.lua`, `modules/`, `styles/` (layer rules, blur, animations) |
| `.config/wallust/` | theming (THEMING.md) |
| `etc/greetd/` | login screen: a second Quickshell config, installed as a copy by `scripts/install-greeter.sh` with `etc/pam.d/` |
| `etc/udev/`, `etc/pacman.d/`, `etc/systemd/user/` | installed as root by `scripts/install-system.sh` |
| `scripts/` | system/greeter installers, generators |

Checks and tests live in `../Jupiter-testing`. Package deps go in Jupiter-installer's `packages/core.txt`/`aur.txt`.

## The shell

```
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

- **Imports are a DAG**: `style/`, `services/` import nothing from the project; `panels/` only those two. `bar/` never imports `dropdown/` or `lock/`. Shared state lives in `services/`.
- **`style/` must run as the greeter** (no readable `$HOME`): read only, no process at construction, never `Quickshell.statePath()` (it creates the dir). Test with `HOME=/nonexistent`.
- `etc/greetd/monitors.lua`, `vconsole.lua` are symlinks into `.config/hypr/modules/`; the installer copies them as files.

## Where things go

| Adding | Goes |
| --- | --- |
| Colour / size, spacing, radius, font, duration | `style/Colors.qml` / `style/Style.qml`, feature group |
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

IPC targets: `qs ipc show`.
