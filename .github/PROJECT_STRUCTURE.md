# Project Structure

```
quickshell-config/
├── shell.qml                  # Entry point — loads Bar, Dropdown, Launcher, Lock;
│                              #   carries //@ pragma UseQApplication (tray menus)
├── .editorconfig              # Enforces 4-space indent, no tabs
├── .qmlls.ini                 # Presence enables quickshell's QML LSP support
│                              #   (quickshell rewrites it as a symlink; gitignored)
├── PROJECT_STRUCTURE.md        # This file
├── README.md                  # Setup + dependencies
├── FEATURES.md                # Everything the shell does, surface by surface
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
│       ├── qmldir              # Registers each widget
│       ├── ClockWidget.qml        # time + date, click opens the calendar zone
│       ├── WorkspaceWidget.qml    # workspace dots + the workspace dropdown
│       ├── BatteryWidget.qml      # charge pill + the battery dropdown
│       ├── BluetoothWidget.qml    # device list + connect/pair, via WidgetPopup
│       ├── WifiWidget.qml         # bar glyph + WidgetPopup holding WifiPanel
│       ├── SystemUsageWidget.qml  # the two load ramps, next to the workspaces
│       ├── UsageMeter.qml         # one of them: a circle that fills
│       ├── BrightnessWidget.qml   # backlight ramp, scroll to adjust
│       ├── BarSeparator.qml       # hairline between groups of widgets
│       ├── VolumeWidget.qml       # Pipewire default sink, click-mute/scroll-adjust
│       ├── SystemTrayWidget.qml   # Quickshell.Services.SystemTray icons
│       ├── PowerWidget.qml        # lock/logout/suspend/reboot/shutdown, via WidgetPopup
│       ├── PowerAction.qml        # one hoverable row of the power menu
│       └── WidgetPopup.qml        # shared popup shell: anchors under its own
│                                  #   widget, closes on Escape or outside click
│
├── panels/                    # Panel content shared between surfaces: each of
│   │                          #   these is opened both from a bar widget and
│   │                          #   from a zone of the swipe dropdown
│   ├── qmldir                 # Registers the panels below
│   ├── BatteryPanel.qml         # state, time left, draw, health
│   ├── BatteryDetail.qml        # one label/value row of it
│   ├── CalendarPanel.qml        # month grid + agenda
│   ├── WifiPanel.qml            # network list, incl. the PSK prompt
│   └── WorkspacePanel.qml       # workspace tiles
│
├── services/                  # Shared singletons: data sources and the state
│   │                          #   that more than one surface reads
│   ├── qmldir                 # Registers the singletons below
│   ├── Brightness.qml           # backlight level, from sysfs
│   ├── CalendarService.qml      # Nextcloud events, via the helper below
│   ├── nextcloud-calendar.py    # CalDAV client (stdlib only), run via Process
│   ├── DropdownState.qml        # Which dropdown zone is open, and where
│   ├── LauncherHistory.qml      # launch counts, persisted under statePath
│   ├── LockService.qml          # Lock state + the PAM conversation
│   ├── SystemUsage.qml          # CPU/memory sampler, read from /proc
│   └── Time.qml                 # Clock source: bar, month grid, lock screen
│
├── dropdown/                  # The three-finger-swipe dropdown
│   ├── qmldir                 # Registers Dropdown
│   └── Dropdown.qml             # Scope: IpcHandler + one overlay PanelWindow
│                              #   that swaps panels/ content by zone
│
├── launcher/                  # App launcher (overlay, toggled by shortcut/IPC)
│   ├── qmldir                 # Registers Launcher, LauncherContent
│   ├── Launcher.qml             # Scope: visibility state, IpcHandler,
│   │                            #   GlobalShortcut, follows the focused monitor
│   └── LauncherContent.qml      # Search input + filtered app ListView
│
└── lock/                      # Session lock (replaces hyprlock)
    ├── qmldir                 # Registers Lock, LockSurface
    ├── Lock.qml                 # Scope: WlSessionLock + IpcHandler + GlobalShortcut
    └── LockSurface.qml          # One monitor's surface: clock, password field
```

## Which module may import which

`style/` and `services/` are leaves: they import nothing from this project.
`panels/` imports those two and nothing else. `bar/`, `dropdown/`, `launcher/`
and `lock/` sit on top and may import any of the three.

That is the whole graph, and it is a DAG on purpose. Nothing in `bar/` may
import `dropdown/` or `lock/`:

- **Shared *state* goes down into `services/`.** `DropdownState` and
  `LockService` live there because the bar's clock opens the calendar zone and
  the bar's power menu raises the lock — if that state sat next to the windows
  it drives, `bar/widgets` would import `dropdown/` and `lock/` while they
  imported it back.
- **Shared *content* goes into `panels/`.** A panel is the inside of a
  dropdown with no opinion about which surface shows it. All four are opened
  from two places: a bar widget's `WidgetPopup` and a zone of the gesture
  dropdown. `WifiPanel` used to live in `bar/widgets` for this reason and
  `dropdown/` reached sideways into it; once three panels were shared, they
  got a module instead.

`Time` is in `services/` for the same reason, even though it started life next
to the clock widget: the bar, the calendar's month grid and the lock screen
all read it, and a singleton three surfaces share is a service, not a widget.

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
  so compositor window rules can still target it individually, set
  `anchorItem: root` so it opens under its own widget, and put your content as
  its default-property children — see `BluetoothWidget.qml`, `WifiWidget.qml`,
  or `PowerWidget.qml` for the pattern.
- **A widget that needs to know which monitor it's on** (for
  `Hyprland.monitorFor()`, or so its `WidgetPopup` opens on the correct
  screen) → add a `required property ShellScreen screen`, and pass
  `screen: root.screen` down from `BarContent.qml`, which gets it from
  `Bar.qml`'s `PanelWindow.screen` (see `WorkspaceWidget.qml`).
- **A new top-level surface** (popup, panel, overlay) → its own folder at the project
  root, following the `launcher/` pattern: a `Scope` or `PanelWindow` file plus a
  content file, registered in its own `qmldir`.
- **A panel shown by more than one surface** → `panels/`, registered in its
  `qmldir`, importing only `services/` and `style/`. Give it the same two
  properties a dropdown zone declares (below) and both surfaces can size it.
- **A new dropdown zone** → a panel in `panels/`, registered in its `qmldir`,
  plus a zone name and a third of the monitor in `services/DropdownState.qml`
  and a `Component` in `Dropdown.qml`. A zone panel declares two properties,
  which together are the whole contract:
  - `readonly property bool wantsKeyboard` — lets the shell raise keyboard
    focus only for a panel that has something to type into;
  - `readonly property int preferredHeight` — the height its content adds up
    to, which `Dropdown.qml` clamps to `Style.dropdown.minHeight`/`maxHeight`.
    Compute it from intrinsic sizes (`contentHeight`, `implicitHeight`) and
    never from the panel's own `height`, which would be a layout loop.
- **Anything fetched from outside the shell** (a network service, a command) →
  a singleton in `services/`, with the talking done by a helper script run
  through `Process` rather than in QML. Keep credentials in the environment or
  the keyring, read by the script; QML should never see them.

## Reading Quickshell service models

Almost every Quickshell service hands you an **`ObjectModel`**, not a QML
`ListModel`: `Bluetooth.devices`, `Networking.devices`, `SystemTray.items`,
`NetworkDevice.networks`, `UPower.devices`, `Hyprland.workspaces`, ...

Two ways to use one, and only two:

```qml
// 1. Directly as a view's model — the delegate gets `modelData`.
ListView {
    model: Bluetooth.devices
    delegate: Row { required property BluetoothDevice modelData; ... }
}

// 2. From JS, through `values` — a plain list.
readonly property bool anyConnected: Bluetooth.devices.values.some(d => d.connected)
```

There is **no `count`** and **no `get(i)`** on the model. Reaching for them is
the single most expensive mistake in this codebase's history, because it does
not throw: `.count` evaluates to `undefined`, `i < undefined` is `false`, the
loop body never runs, and the binding quietly settles on its default value.
Three widgets shipped broken this way and the log was completely clean — see
`TODO.md` Phase 2.5.

`ListView.count` / `Repeater.count` are unrelated and perfectly fine; those are
properties of the *view*, not of the model.

More generally: before using any Quickshell property or method, check it
against the installed type definitions rather than guessing from the name.

```sh
grep -rn '"propertyName"' /usr/lib/qt6/qml/Quickshell/**/*.qmltypes
```

Those files list every property, method, signal and enum the installed version
actually exposes, and they match the running binary — which the online docs may
not, if the installed version has moved on.

## Functions called from bindings need return types

```qml
function sameDay(left: date, right: date): bool { ... }   // yes
function sameDay(left: date, right: date) { ... }         // logs an error per call
```

A QML function with no return annotation is treated as returning `void`. It
still returns the right value, but every call site whose value is used logs

```
<value> should be coerced to void because the function called is
insufficiently annotated. The original value is retained.
```

which for a 42-cell month grid means 42 errors per repaint. Annotate the
return type of anything a binding reads.

The catch: qmllint 1.0 crashes (exit 255, silently) on `void` and on `var`
anywhere in a signature — parameter or return. So

- functions called only as statements are left unannotated, as the rest of the
  project does (`VolumeWidget.adjust`);
- functions whose value is read get a concrete return type (`bool`, `date`,
  `int`, `string`, `real`, `ShellScreen`, ...);
- a function that would return a JS array becomes a `property var` binding
  instead — see `CalendarService.eventsByDay`, which is also why the month
  grid does 42 lookups instead of 42 list scans;
- the only files that need `void` are the two with an `IpcHandler`, and those
  are excluded from linting (see README).

## Full-screen overlays and the exclusive zone

`WidgetPopup`, `Dropdown` and `Launcher` are all one full-screen transparent
window with the real panel positioned inside it. Two things follow from that,
and both were once got wrong:

- The compositor already hands such a window **the screen minus every
  exclusive zone**, so its y=0 is below the bar, not at the top of the screen.
  A top margin that adds the bar's height back counts it twice —
  `Style.popup.topMargin` is just the gap for this reason.
- The window's x=0 is the screen's left edge, while an item measured with
  `QsWindow.itemRect()` is in *its own* window's frame. The bar's window starts
  `Style.bar.sideGap` in, and `QsWindow` exposes no absolute position, so that
  token is what reconciles the two.

## Keyboard focus on an overlay

`WlrKeyboardFocus.OnDemand` is not enough on its own. An on-demand layer
surface is given focus when the user interacts with *that surface*, and these
open from a click on the bar or a touchpad gesture — neither of which is a
click on the overlay. Without focus, `Keys.onEscapePressed` never fires.

`HyprlandFocusGrab` is what makes the compositor hand focus over and give it
back on close. Pair it with a `FocusScope` around the content, so that a child
input (the Wi-Fi password field) releasing focus leaves it on the scope rather
than nowhere, and Escape still arrives.

One grab supersedes another, so this also means only one overlay is open at a
time — opening a second popup closes the first.

## FileView is asynchronous unless you make it otherwise

Three bugs in a row came from this, so it is worth stating plainly.

- `path` starts a **load as soon as it is set**, and `blockLoading` /
  `blockAllReads` are only pushed into the underlying object when `text()` or
  `data()` is called. Setting the path and reading in the same tick reads
  nothing — and a `FileView` asked for content it has not loaded returns `""`
  rather than complaining.
- A QML singleton is built on **first use**, so its first use is in the same
  tick as its construction. `LauncherHistory` reads its file from
  `Component.onCompleted` for exactly this reason: without it, the first
  launch of a session wrote an empty adapter over a file full of real counts.
- Never read a `FileView` from a property change handler for something its
  `path` depends on. A handler runs *before* the bindings that depend on that
  property are re-evaluated, so the view's path is still the old one.
  `Brightness` reads from a timer, which fires a tick later, instead.
- The working shape for a file that changes under you is
  `reload()` then `text()`, with `blockAllReads: true` — see
  `SystemUsage.sampleCpu()`. Do not also call it from `onLoaded`: `reload()`
  fires `loaded`, and the pair recurses until the stack gives out.
- `watchChanges` does nothing for **sysfs**. Those attributes support `poll()`
  on an open descriptor, not the inotify events `QFileSystemWatcher` wants.

## Units that aren't what they look like

- `UPowerDevice.percentage` is a **0.0–1.0 ratio**, not 0–100 (quickshell
  scales UPower's wire value by 0.01). Multiply by 100 before displaying.
- `WifiNetwork.signalStrength` is likewise **0.0–1.0**.
- `PwNodeAudio.volume` is **0.0–1.0**.
