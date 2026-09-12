# Quickshell config

A [Quickshell](https://quickshell.org/) desktop shell for Hyprland: a top bar
(clock, Bluetooth, battery) and an app launcher, both built as widget-styled
QML.

See `PROJECT_STRUCTURE.md` for the file layout and conventions, and
`TODO.md` for the current roadmap.

## Dependencies

- [Quickshell](https://quickshell.org/) — the v0.3.0 docs are the reference
  per `llm.md`; the version actually installed here is **0.3.1**, and the
  APIs this config uses were verified against
  `/usr/lib/qt6/qml/Quickshell/**/*.qmltypes` on that install
- [Hyprland](https://hyprland.org/) — `Quickshell.Wayland` (`WlrLayershell`)
  and `Quickshell.Hyprland` (`GlobalShortcut`) assume a wlroots/Hyprland
  compositor
- A **Nerd Font** with the glyphs used in the bar widgets — currently
  configured as `JetBrainsMono Nerd Font` in `style/Style.qml`
- `UPower` running, for `Quickshell.Services.UPower` (battery widget)
- `BlueZ` running, for `Quickshell.Bluetooth` (Bluetooth widget)
- `NetworkManager` running, for `Quickshell.Networking` (Wi-Fi widget) —
  it's currently the only backend that module supports
- `PipeWire` running, for `Quickshell.Services.Pipewire` (volume widget)
- A tray-item-emitting DBus session (most apps that put icons in a tray
  already do this) for `Quickshell.Services.SystemTray`. Note that tray
  *context menus* are platform menus, which need `//@ pragma UseQApplication`
  at the top of `shell.qml` — it's there, but it only takes effect on a full
  quickshell restart, never on a config reload.
- An icon theme, for the launcher's application icons. Quickshell resolves
  these through `QIcon::fromTheme`, so entries are found in `hicolor` and in
  `/usr/share/pixmaps` even with no desktop-environment theme configured — on
  this system 34 of 43 `.desktop` entries resolve that way. The remainder are
  apps whose named icon simply isn't installed anywhere Qt looks; those fall
  back to a generic Nerd Font glyph in the launcher rather than showing a gap.
  Setting an explicit theme (`QT_QPA_PLATFORMTHEME=gtk3` plus
  `gtk-icon-theme-name=` in `~/.config/gtk-3.0/settings.ini`) widens coverage.
- A screen locker such as `hyprlock` or `swaylock`, for the power menu's
  "Lock" action — there's no native Quickshell lock screen yet (see
  `TODO.md` Phase 4)

## Running

```sh
qs -c <config-name>
```

where `<config-name>` matches however this directory is placed under
`~/.config/quickshell/`.

## Launcher shortcuts

- **Hyprland bind** (no process spawn per press):
  ```
  bindd = SUPER, R, Toggle launcher, global, quickshell:launcherToggle
  ```
- **Manual/scripted, compositor-independent:**
  ```sh
  qs -c <config-name> ipc call launcher toggle
  ```

## Validating changes

```sh
qmllint -I /usr/lib/qt6/qml $(find . -name '*.qml' ! -name 'Launcher.qml')
```

`launcher/Launcher.qml` is excluded because qmllint 1.0 crashes (exit 255, no
output) on any `function f(): void` return annotation, and Quickshell's
`IpcHandler` requires type annotations on its functions. That's a linter bug,
not a problem with the file.

Quickshell watches these files and hot-reloads on save, so the fastest check is
usually to just save and read the log:

```sh
qs log -r '*.debug=true;*.info=true' -- /run/user/1000/quickshell/by-id/<id>/log.qslog
```

Be aware that a wrong Quickshell API can fail *silently* — see the
`ObjectModel` note in `PROJECT_STRUCTURE.md` and Phase 2.5 in `TODO.md`.
