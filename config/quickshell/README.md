# Quickshell config

A [Quickshell](https://quickshell.org/) desktop shell for Hyprland: a top bar
(clock, Bluetooth, battery) and an app launcher, both built as widget-styled
QML.

See `PROJECT_STRUCTURE.md` for the file layout and conventions, and
`TODO.md` for the current roadmap.

## Dependencies

- [Quickshell](https://quickshell.org/) — targeting the v0.3.0 docs/API
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
  already do this) for `Quickshell.Services.SystemTray`
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
