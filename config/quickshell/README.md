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
