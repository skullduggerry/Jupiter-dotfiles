# Project structure — agent reference

Working notes for Claude Code sessions on `config/quickshell/`. Rules for how
to write code here live in `config/quickshell/llm.md`; this file is the map and
the list of things that have already cost a bug. Colour, wallust templating and
Qt/KDE theming are in `.github/THEMING.md`.

Installed: **Quickshell 0.3.1**, **Hyprland 0.56.2**, Arch Linux, Qt 6.

## Layout

```
config/quickshell/
├── shell.qml              Entry point: Bar, Dropdown, Launcher, Lock.
├── llm.md                 Coding rules for agents.
├── style/                 Colors.qml, Style.qml — every colour and dimension.
├── services/              Singletons: data sources + cross-surface state.
│                          Brightness, CalendarService (+ nextcloud-calendar.py),
│                          DropdownState, LauncherHistory, LockService,
│                          NotificationService, SystemUsage, Time.
├── panels/                Panel content shown by more than one surface:
│                          AudioPanel, BatteryPanel (+BatteryDetail),
│                          BluetoothPanel, BrightnessPanel, CalendarPanel,
│                          NotificationPanel (+NotificationEntry), PanelSlider,
│                          WifiPanel, WorkspacePanel.
├── bar/                   Bar.qml (PanelWindow per screen) + BarContent.qml,
│   └── widgets/           one file per widget, plus WidgetPopup.qml (the
│                          shared dropdown shell), QuickPager.qml (the swipeable
│                          quick-settings dropdown), PowerAction.qml, and
│                          TrayMenu.qml + TrayMenuItem.qml.
├── dropdown/              Dropdown.qml — one overlay for all three swipe zones
│                          (workspaces, calendar, quick settings).
├── notifications/         Toasts.qml (the popup stack window) + Toast.qml.
├── launcher/              Launcher.qml (scope/IPC/shortcut) + LauncherContent.qml.
└── lock/                  Lock.qml (WlSessionLock) + LockSurface.qml (per monitor).
```

## Import graph

`style/` and `services/` are leaves — they import nothing from this project.
`panels/` imports those two only. `bar/`, `dropdown/`, `launcher/`, `lock/` sit
on top and may import any of the three. It is a DAG, deliberately:

- **Shared state goes down into `services/`.** `DropdownState` and `LockService`
  live there because the bar's clock opens the calendar zone and the bar's power
  menu raises the lock. State next to the window it drives would make
  `bar/widgets` import `dropdown/`/`lock/` while they imported it back.
- **Shared content goes into `panels/`.** A panel is the inside of a dropdown
  with no opinion about which surface shows it. All four are opened from both a
  bar widget's `WidgetPopup` and a zone of the gesture dropdown.

Nothing in `bar/` may import `dropdown/` or `lock/`.

## Conventions

- **Formatting is `qmlformat`, i.e. the official Qt QML conventions** — member
  ordering (id, properties, signals, functions, object properties, children),
  semicolons in functions and expressions, grouped property notation. Run
  `scripts/check.sh --fix`; the pre-commit hook does it for staged files. The
  earlier house style (a `// path/File.qml` header on line 1, no comments, blank
  lines between property groups) was dropped: it was a stand-in for a real
  standard and it fought the formatter, which relocates such headers below the
  imports.
- **`pragma` stays on line 1.** qmlformat sorts pragmas below the imports;
  Quickshell's docs say to put `pragma Singleton` at the top of the file, and
  Quickshell outranks Qt in this project's documentation order, so
  `scripts/hoist-pragmas.py` puts it back after formatting. Both forms load.
- Every imported folder has a `qmldir` declaring its types explicitly
  (`BluetoothWidget 1.0 BluetoothWidget.qml`, `singleton Time 1.0 Time.qml`).
  Required for `pragma Singleton`; done everywhere else for consistency.
- 4-space indent, no tabs (`.editorconfig`).
- PascalCase files, camelCase ids and properties, typed properties over `var`.

## Where things go

| Adding | Goes |
| --- | --- |
| A colour | `style/Colors.qml`, in the feature group |
| A spacing/size/radius/font value | `style/Style.qml`, same grouping |
| A bar widget | `bar/widgets/` + its `qmldir` + a `Row` in `BarContent.qml` |
| A widget dropdown | wrap it in `WidgetPopup` — never hand-roll another catcher window |
| A quick-settings page | a panel in `panels/` + a `page*` index and `Component` in `QuickPager` |
| A panel shown by two surfaces | `panels/`, importing only `services/` and `style/` |
| A new swipe zone | a panel, a zone name in `DropdownState`, a `Component` in `Dropdown.qml` |
| Anything fetched from outside | a `services/` singleton, with a helper script run through `Process` |
| A new top-level surface | its own folder + `qmldir`, following `launcher/` |

A widget that needs to know its monitor (for `Hyprland.monitorFor()`, or so its
popup opens on the right screen) declares `required property ShellScreen screen`
and gets it passed down from `BarContent.qml`, which gets it from `Bar.qml`'s
`PanelWindow.screen`.

`WidgetPopup` usage: set `anchorItem: root` so it opens under its own widget, a
distinct `namespaceSuffix`, and put content as default-property children. See
`PowerWidget.qml`.

**The suffix must end in `-popup`.** The frosted-glass backdrop is not drawn by
quickshell at all — it is a Hyprland layer rule in
`config/hypr/styles/layout.lua` matching `^quickshell:.*-popup$`. A popup named
anything else renders as a flat translucent panel next to blurred ones, with
nothing in the quickshell log to explain it. `quicksettings-popup` was briefly
`quick-pager` and lost its blur exactly this way.

The calendar panel drives `CalendarService`'s fetch window from the month it
displays, plus `Style.calendar.upcomingLookahead` days past the last visible
day. That tail is what feeds the agenda's "upcoming" list when the selected day
has nothing on it — without it the list could only see as far as the grid, which
late in a month is a day or two. It is a fixed tail rather than an open-ended
range so paging to a distant month stays one bounded request.

A panel shown by a dropdown zone declares two properties, which are the whole
contract:

- `readonly property bool wantsKeyboard` — raises keyboard focus only for a
  panel with something to type into;
- `readonly property int preferredHeight` — what its content adds up to, which
  the owning surface clamps. Compute it from intrinsic sizes (`contentHeight`,
  `implicitHeight`), never from the panel's own `height` — that is a layout loop.

Credentials never reach QML. `nextcloud-calendar.py` reads them from the
environment or the keyring itself.

## The quick-settings pager

Battery, Wi-Fi, Bluetooth, Audio and Brightness do **not** own popups. The pages
live in `panels/QuickSettingsPanel.qml`, which is shown by two surfaces: the bar,
through the thin `QuickPager` wrapper that `BarContent` owns per screen, and the
right zone of the three-finger dropdown. Adding a page means a panel in
`panels/`, a `page*` index and a `Component` in `QuickSettingsPanel`.

Paging is a **two-finger swipe**, i.e. horizontal wheel events, not a drag.
Measured on this touchpad, one swipe is ~83 wheel events summing to ~17500 of
`angleDelta.x`, so a per-event threshold is useless -- at the original step of
120 a single swipe advanced 146 pages. `QuickSettingsPanel` therefore commits
**one page per gesture**: it pages once when travel crosses
`Style.pager.swipeStep`, then ignores the rest until `swipeIdle` (180ms of no
wheel) marks the gesture finished.

**The dismiss-on-click is delayed, and a wheel event cancels it.** A two-finger
swipe on this touchpad delivers a tap *click* before the scroll -- confirmed by
logging: `backdrop CLICKED` landed first, then 83 wheel events arrived at a
popup that had already closed. So the popup and the dropdown both start a
`Style.popup.dismissDelay` timer instead of hiding immediately, and any wheel
stops it. Both the backdrop click and `HyprlandFocusGrab.onCleared` go through
that timer; routing only one of them still closed instantly.

Wheel is handled **only** on the popup's full-screen backdrop, never on the
panel, which is what makes the pointer's position irrelevant. Any `Flickable`
inside a page must therefore set `flickableDirection: Flickable.VerticalFlick`,
or it swallows the horizontal wheel before the backdrop sees it -- the Wi-Fi and
Bluetooth device lists both do.
`PathView.interactive` is off precisely so a one-finger drag belongs to whatever
is under it — the volume and brightness sliders — instead of dragging the pager
out from under them. `WidgetPopup` re-emits wheel from its full-screen backdrop
as `wheeled()`, which is what lets the pager respond wherever the pointer is
rather than only over the panel itself.

It is a `PathView`, not a `ListView`, because it wraps: swiping left from the
first page lands on the last, so no page is more than two swipes away. There is
no `SwipeView` because nothing in this project imports `QtQuick.Controls`, and
that is worth keeping.

**`PathView` spacing is path length divided by `pathItemCount`, not the delegate
width.** With `pathItemCount: 3` the path must be three page-widths long
(`-width` to `width * 2`) or the pages overlap and you see two panels drawn on
top of each other. A path of `-width/2` to `width * 1.5` spaces them two thirds
of a page apart and looks like a rendering bug.

`cacheItemCount` keeps all five delegates alive so a page keeps its state while
you swipe past it. That means a panel is constructed whether or not it is
showing, so anything expensive must be gated on being the current page —
`WifiPanel.active` is bound to `root.visible && pages.currentIndex === pageWifi`
so scanning only runs while it is on screen.

## Icons

Bar icons are monochrome, on the three tones in `Colors.icon`: `active` (white)
for something that wants attention, `inactive` for the resting state, `disabled`
for off or unavailable. State that used to be carried by hue is carried by the
glyph instead — the Wi-Fi ramp, the battery fill, the notification count.

**The Font Awesome range of the Nerd Font is not covered by `Style.text.font`.**
`\uf028` (speaker) rendered as an empty box in the bar for a long time. The
Material Design range (`U+F0000`+) does render: bluetooth `U+F00B1`, wifi
`U+F0928`, brightness `U+F00DF`, volume `U+F057E`. Prefer it for new icons, and
check a new glyph actually draws before assuming the codepoint is wrong.

## The system tray

Three things about it are deliberate.

**Duplicate icons are filtered by SNI id.** `nm-applet` and `blueman` are in
`SystemTrayWidget.hiddenIds` because the shell has its own Wi-Fi and Bluetooth
widgets, and the two applets' tray icons say the same thing twice. The
processes stay running on purpose: nm-applet is NetworkManager's secret agent
and blueman-applet is the BlueZ pairing agent, so killing them costs
functionality the shell does not replace. Filtering the icon costs nothing.
Read the ids of what is registered with:

```bash
busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher \
    org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems
busctl --user get-property <bus> <path> org.kde.StatusNotifierItem Id
```

**Icons are tinted to a single tone to match the bar**, through a `MultiEffect`
over the `IconImage`. `Style.tray.colorization` is the one knob: `1` repaints
every icon in `Colors.icon.*` whatever its artwork, `0` leaves it alone.

Do **not** put `saturation` back alongside it. MultiEffect applies saturation
*after* colorization, so the previous `saturation: -1` stripped the tint out
again and colorization looked like it did nothing at all — including with
`colorizationColor` forced to pure red. That cost three round trips to diagnose.

Colorization neutralises hue but does not flatten luminance, so a dark
filled-disc icon still reads heavier than line art. Flattening that too would
need an alpha-as-mask `ShaderEffect` and a `qsb` build step.

The source `IconImage` is `visible: false`, which is the documented Qt pattern:
a `ShaderEffectSource` renders a hidden item. An item whose SNI status is
`NeedsAttention` gets the brighter `Colors.icon.active`; a `Passive` one is
dimmed.

**Menus are rendered in QML, not as platform menus.** `TrayMenu` is a
`WidgetPopup` driven by `QsMenuOpener`, so a tray menu looks like every other
dropdown. `QsMenuEntry.triggered()` is a *signal you emit* to activate an entry.
Submenus (`hasChildren`) navigate in place with a back row rather than opening a
second window. Because nothing calls `SystemTrayItem.display()` any more,
`shell.qml` no longer needs `//@ pragma UseQApplication` — it was removed, and
putting it back would need a full restart, not a reload.

## Notifications

The shell owns `org.freedesktop.Notifications`. Four things about the API are
easy to get wrong, and the first two are silent:

- **A notification is discarded unless you set `tracked = true`** in the
  `NotificationServer.notification` handler. Nothing warns you; they simply
  never appear.
- **The object is destroyed as soon as the `closed` handlers exit.** Holding
  `Notification` references in a plain JS array therefore dangles.
  `NotificationService.popupIds` holds *ids* and derives the popup list by
  filtering `trackedNotifications`, so a closed notification drops out on its
  own.
- **`expireTimeout` is in milliseconds** — the same unit `Timer.interval` takes
  and the same unit the DBus `Notify` call carries, so it is used as-is. This
  doc claimed seconds for a while and `Toast.qml` multiplied by 1000, which
  turned every app-specified timeout into 1000x itself: `notify-send -t 2000`
  stayed up for 33 minutes. Only `-1` ("server decides") should fall through to
  `Style.notifications.timeout`. Verified by probe: no `-t` expires at 6.2s,
  `-t 2000` did not expire at all until the conversion was removed.
- **Every capability except `bodySupported` defaults to false**, and each is
  advertised over DBus, so only turn on what is actually rendered. Currently:
  persistence, body, body-markup, actions, icon-static. Inline reply is *not*
  implemented and so is not advertised — `sendInlineReply()` may only be called
  when it is.

Toast expiry and dismissal are deliberately different: a toast timing out calls
`expirePopup()`, which hides the toast but leaves the notification in the
centre; the `×` calls `dismiss()`, which destroys it everywhere. A `transient`
notification is the exception — the spec says it should skip any persistent
area, so it is expired rather than kept, and `NotificationService.list` filters
it out of the centre.

Critical notifications never auto-expire and keep their colour; right-clicking
the bar's bell toggles do-not-disturb, which suppresses toasts for everything
except critical.

**Whatever else owns the bus name has to be masked**, since two daemons cannot
hold it at once. Which daemon that is differs per machine — this laptop shipped
`dunst`, the desktop had `swaync` — so read it off the bus rather than assuming:

```bash
busctl --user call org.freedesktop.DBus /org/freedesktop/DBus \
    org.freedesktop.DBus GetConnectionUnixProcessID s org.freedesktop.Notifications
```

```bash
systemctl --user mask --now dunst.service     # undo: systemctl --user unmask
```

Both units are `Type=dbus` with `BusName=org.freedesktop.Notifications`, so they
are DBus-activated and show as `static`/`disabled` while still starting on
demand — disabling is not enough, it has to be masked.

The shell needs no restart afterwards. `NotificationService` logs `Registration
will be attempted again if the active service is unregistered` on startup and
takes the name the moment the other daemon drops it.

## Things that have already cost a bug

**Quickshell services hand you an `ObjectModel`, not a `ListModel`.**
`Bluetooth.devices`, `Networking.devices`, `SystemTray.items`,
`WifiDevice.networks`, `UPower.devices`, `Hyprland.workspaces`, … There is **no
`count` and no `get(i)`**. Use it two ways only:

```qml
ListView { model: Bluetooth.devices; delegate: Row { required property BluetoothDevice modelData } }
readonly property bool any: Bluetooth.devices.values.some(d => d.connected)
```

Reaching for `.count` does not throw: it is `undefined`, `i < undefined` is
`false`, the loop never runs, and the binding settles on its default. Three
widgets shipped broken this way with a clean log. (`ListView.count` and
`Repeater.count` are properties of the *view* and are fine.)

**A delegate outlives its model row.** A view bound *directly* to an
`ObjectModel` re-evaluates its delegate's bindings with `modelData === null`
when a row is removed, before destroying the delegate. Every unguarded
`row.modelData.<property>` then throws — 55 `TypeError`s in five minutes from
the Wi-Fi list alone, and silently, because a failed binding just keeps its last
value on screen. Guard once per fact on the delegate root, not at each use site:

```qml
readonly property bool connected: networkRow.modelData !== null && networkRow.modelData.connected
```

Signal handlers (`onClicked`, `Connections`) need no guard — they only run while
the row exists. Delegates over a *derived* list (`.values.filter(...)`) are
immune: a new JS array identity destroys the delegates outright, with no null
phase. It is the same split as above — `model:` on the ObjectModel needs the
guard, `.values` does not. Fixed in `WifiPanel`, `BluetoothWidget` and
`WorkspaceWidget`; `Bar.qml` is fine because it only passes `modelData` to
`screen:` without dereferencing it.

**A function whose return value is read from a binding needs a return type.**
Without one the engine treats it as `void` and logs an error per call site — 42
of them for a month grid. Catch: qmllint 1.0 crashes (exit 255, silently) on
`void` and `var` anywhere in a signature. So: statement-only functions stay
unannotated; value-returning ones get a concrete type; a function that would
return a JS array becomes a `property var` binding instead (see
`CalendarService.eventsByDay`); the three files with an `IpcHandler` need
`: void` and are excluded from linting.

**A full-screen overlay is already positioned below the bar's exclusive zone.**
The compositor hands such a window the screen minus every reserved strip, so its
y=0 is under the bar — adding the bar height to a top margin counts it twice.
Its x=0 *is* the screen's left edge, while `QsWindow.itemRect()` reports in the
item's own window frame; the bar's window starts `Style.bar.sideGap` in, and
`QsWindow` exposes no absolute position, so that token reconciles the two.

**`WlrKeyboardFocus.OnDemand` alone does not give an overlay focus.** An
on-demand layer surface gets focus when the user interacts with *it*, and these
open from a click on the bar or a gesture. Without focus `Keys.onEscapePressed`
never fires. `HyprlandFocusGrab` is what hands focus over and gives it back;
pair it with a `FocusScope` around the content so a child input releasing focus
leaves it on the scope. One grab supersedes another, so only one overlay is open
at a time.

**`FileView` is asynchronous unless you make it otherwise.**

- `path` starts a load as soon as it is set, and `blockLoading`/`blockAllReads`
  are only applied when `text()`/`data()` is called. Setting the path and
  reading in the same tick reads nothing — and returns `""` rather than
  complaining.
- A QML singleton is built on first use, so its first use is in the same tick as
  its construction. `LauncherHistory` reads from `Component.onCompleted` for
  this reason; without it the first launch of a session overwrote real counts.
- Never read a `FileView` from a change handler for something its `path` depends
  on — a handler runs *before* the dependent bindings re-evaluate, so the path
  is still the old one. `Brightness` reads from a timer instead.
- The working shape is `reload()` then `text()` with `blockAllReads: true`
  (`SystemUsage.sampleCpu`). Do not also call it from `onLoaded`: `reload()`
  fires `loaded` and the pair recurses.
- `watchChanges` does nothing for **sysfs** — those attributes support `poll()`,
  not the inotify events `QFileSystemWatcher` wants.
- `writeAdapter()` is asynchronous; a second write started mid-flight resyncs
  from the first one's snapshot. Debounce writes.

**Units that aren't what they look like.** `UPowerDevice.percentage`,
`WifiNetwork.signalStrength` and `PwNodeAudio.volume` are all **0.0–1.0 ratios**,
not 0–100.

**Private-use glyphs get lost in transit.** The calendar's month chevrons were
silently emptied to `""` at some point by a tool that dropped the codepoints.
Prefer `""` escapes over pasted Nerd Font glyphs in new code.

## Verifying an API exists

The online docs may be ahead of the installed binary. The type definitions are
not:

```bash
grep -rn '"propertyName"' /usr/lib/qt6/qml/Quickshell/**/*.qmltypes
```

They list every property, method, signal and enum the running version exposes.
Note `Quickshell.Widgets` types are plain QML files, not in the `.qmltypes` —
read `/usr/lib/qt6/qml/Quickshell/Widgets/*.qml` directly.

## Validating a change

```bash
scripts/check.sh          # verify everything
scripts/check.sh --fix    # format first, then verify
scripts/install-hooks.sh  # once per clone: pre-commit + pre-push
```

`check.sh` runs formatting, the `.editorconfig` whitespace rules, qmllint,
qmldir completeness, the `-popup` namespace rule the blur depends on, a
repo-wide Nerd Font glyph count against HEAD, python/lua/shell parsing, the
greeter compositor config, and `tests/`. The pre-commit hook formats staged QML
and re-stages it; pre-push runs the suite without modifying anything.

**Two constructs defeat the Qt tooling**, and files using them are skipped
automatically rather than listed by name:

- a `: void` return type — crashes qmllint (exit 255, silently) *and* makes
  qmlformat exit non-zero with empty output. `Dropdown`, `Launcher` and `Lock`
  need it for their `IpcHandler` functions.
- the spread operator `...` — qmlformat only. `NotificationService` and
  `LauncherContent` use it.

Underneath, qmllint is still:

```bash
qmllint -I /usr/lib/qt6/qml $(find . -name '*.qml' ! -name 'Launcher.qml' ! -name 'Dropdown.qml' ! -name 'Lock.qml')
```

Quickshell hot-reloads on a **content** change to any loaded file, not just
`shell.qml`. `touch` alone does nothing — an identical file is not a change — so
never use it to force a reload.

The watches can go stale, though: if the files are replaced underneath a running
instance (a fresh clone or a `git checkout` of the whole tree while `qs` is up),
the reload stops firing and edits appear to do nothing. That is how an already
correct fix can look broken — you re-test and measure the old code. Confirm a
reload actually happened before concluding anything about a change:

```bash
qs log -r '*.info=true' -- /run/user/1000/quickshell/by-id/<id>/log.qslog \
    | grep -c 'Reloading configuration'
```

If the count did not move, write to `shell.qml` (a real edit, not a `touch`) to
force one. A failed reload is loud — `Failed to load configuration` plus the
offending file and line — and leaves the previous config running:

```bash
qs log -r '*.debug=true;*.info=true' -- /run/user/1000/quickshell/by-id/<id>/log.qslog
```

A wrong Quickshell API can fail **silently** — see the `ObjectModel` note above.

## Entry points, for testing by hand

```bash
qs ipc call launcher toggle
qs ipc call dropdown openAt 904 740    # zone from a pointer position
qs ipc call dropdown open calendar     # a zone by name
qs ipc call dropdown open quicksettings
qs ipc call lock lock                  # no unlock IPC exists, by design
qs ipc call lock locked
```

`SUPER+O` and `SUPER+L` are `GlobalShortcut`s bound with `hl.dsp.global(...)`;
the three-finger swipe is an `hl.gesture` block calling `dropdown openAt`. All
in `config/hypr/modules/keybinds.lua`.

Hyprland here is configured in **Lua**, so `hyprctl dispatch` takes a Lua
expression — `hyprctl dispatch 'hl.dsp.focus({ monitor = "eDP-1" })'`, not
`hyprctl dispatch focusmonitor eDP-1`. The hyprlang spelling fails with exit 7
and does nothing. The header comment in `config/hypr/hyprland.lua` has the
details and the dispatcher list.

## Runtime facts that affect the code

- **NetworkManager** is the only backend `Quickshell.Networking` supports.
- The lock authenticates against pam.d **`login`** (`LockService.pamConfig`);
  `pam_unix` goes through setuid `unix_chkpwd`, so quickshell needs no
  privileges. A config reload while locked used to drop the lock — `locked`
  lives in `PersistentProperties` now.
- `misc:allow_session_lock_restore` is on in `config/hypr/modules/session.lua`,
  so a restarted shell can retake an orphaned lock (TTY → `qs` → unlock).
- Brightness **writes** go through `swayosd-client`, the same path the
  compositor's brightness keys use; reads come from `/sys/class/backlight`, and
  the widget hides itself when that directory is empty.
- A DBus-activated notification daemon will silently hold
  `org.freedesktop.Notifications` unless masked, and a shell-owned notification
  server cannot coexist with it. Masked here: `dunst`. `swaync` is not installed
  on this machine.
