# Project Structure

```
quickshell-config/
├── shell.qml                  # Entry point — loads Bar and Launcher scopes
├── .editorconfig              # Enforces 4-space indent, no tabs
├── PROJECT_STRUCTURE.md        # This file
├── README.md                  # Setup + dependencies
├── TODO.md                    # Roadmap, grouped by phase
│
├── style/                     # Theming singletons, imported everywhere via "../style" / "../../style"
│   ├── qmldir                 # Registers Colors and Style as singletons
│   ├── Colors.qml              # ALL color values live here
│   └── Style.qml                # ALL spacing/size/radius/font values live here
│
├── bar/                       # Top panel
│   ├── qmldir                 # Registers Bar, BarContent
│   ├── Bar.qml                  # PanelWindow, one per screen (Quickshell.screens)
│   ├── BarContent.qml           # Left/center/right Row layout
│   └── widgets/                # Individual bar widgets
│       ├── qmldir              # Registers each widget + the Time singleton
│       ├── ClockWidget.qml
│       ├── Time.qml              # Singleton clock source, feeds ClockWidget
│       ├── WorkspaceWidget.qml    # Hyprland workspaces (left zone)
│       ├── BatteryWidget.qml
│       ├── BluetoothWidget.qml    # device list + connect/pair, via WidgetPopup
│       ├── WifiWidget.qml         # SSID list + connect/disconnect, via WidgetPopup
│       ├── VolumeWidget.qml       # Pipewire default sink, click-mute/scroll-adjust
│       ├── SystemTrayWidget.qml   # Quickshell.Services.SystemTray icons
│       ├── PowerWidget.qml        # lock/logout/suspend/reboot/shutdown, via WidgetPopup
│       └── WidgetPopup.qml        # shared click-outside-to-close popup shell
│
└── launcher/                  # App launcher (overlay, toggled by shortcut/IPC)
    ├── qmldir                 # Registers Launcher, LauncherContent
    ├── Launcher.qml             # Scope: visibility state, IpcHandler, GlobalShortcut
    └── LauncherContent.qml      # Search input + filtered app ListView
```

## The `qmldir` convention

Every folder that's imported as a module (`import "./widgets"`, `import "../style"`, etc.)
has a `qmldir` file that explicitly declares which `.qml` files are exposed as which
type names, e.g.:

```
BluetoothWidget 1.0 BluetoothWidget.qml
singleton Time 1.0 Time.qml
```

This project follows that pattern consistently now — `launcher/qmldir` was **added**
during this cleanup pass; it existed for `bar/` and `style/` already but was missing
for `launcher/`, so `Launcher`/`LauncherContent` were previously resolving through
QML's implicit directory-import fallback rather than an explicit declaration. Both
work, but explicit registration is what the rest of the project does, is required
for `pragma Singleton` types (see `Time.qml`, `Colors.qml`, `Style.qml`), and makes
versioning (`1.0`) meaningful if this ever needs a bump later.

## Where things go

- **Any color** → `style/Colors.qml`, grouped by feature (`bluetooth`, `battery`, ...).
- **Any spacing/size/radius/padding/font value** → `style/Style.qml`, grouped the same way.
- **A new bar widget** → `bar/widgets/`, registered in `bar/widgets/qmldir`, added to
  the appropriate `Row` in `BarContent.qml`.
- **A widget-attached popup/dropdown** (device list, menu, ...) → wrap it in
  `bar/widgets/WidgetPopup.qml` rather than hand-rolling another fullscreen
  catcher window. Give it a distinct `namespaceSuffix` (e.g. `"wifi-popup"`)
  so compositor window rules can still target it individually, and put your
  content as its default-property children — see `BluetoothWidget.qml`,
  `WifiWidget.qml`, or `PowerWidget.qml` for the pattern.
- **A widget that needs to know which monitor it's on** (for
  `Hyprland.monitorFor()`, or so its `WidgetPopup` opens on the correct
  screen) → add a `required property ShellScreen screen`, and pass
  `screen: root.screen` down from `BarContent.qml`, which gets it from
  `Bar.qml`'s `PanelWindow.screen` (see `WorkspaceWidget.qml`).
- **A new top-level surface** (popup, panel, overlay) → its own folder at the project
  root, following the `launcher/` pattern: a `Scope` or `PanelWindow` file plus a
  content file, registered in its own `qmldir`.
