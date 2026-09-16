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
- **Every panel in `panels/` owns its own padding and chrome.** The shape is one
  `Item { anchors.fill: parent; anchors.margins: Style.bar.padding }` wrapping a
  header `Item` of `Style.popup.itemHeight`, a one-pixel `Colors.base.border`
  separator, then the content — and a `preferredHeight` that starts with
  `Style.bar.padding * 2`. Hosts (the dropdown's `Loader`, `QuickPager`) add no
  margins of their own, so a page looks identical in either surface and the
  pager can slide pages edge to edge. `AudioPanel`, `BrightnessPanel` and
  `BluetoothPanel` were written without it: their titles sat on the rounded
  corner, the right-hand column was clipped by the border, and every title
  jumped to a different height as you swiped.
- **One icon family across the bar, and one rule for colour.** Every glyph is a
  Material Design one from the Nerd Font (`nf-md-*`, the U+F0000 plane) at
  `Style.text.iconSize`, wrapped in `implicitWidth: row.implicitWidth +
  Style.widgets.padding * 2` so the row spaces evenly. The right-hand side used
  to break this three ways: the notifications bell was Font Awesome
  (`\uf0f3`), the battery was a hand-drawn `Rectangle` pill rather than a
  glyph, and volume was the only icon carrying a percentage. Colour is not
  decoration — the row is monochrome, and a colour means something needs
  attention, the way `UsageMeter` turns orange past `Style.usage.warnAbove`. A
  battery is white while charging (the glyph already says so) and only goes
  orange at 20% and red at 10%, and the bell is
  `Colors.notification.urgent` only when something critical is waiting —
  `NotificationService.hasCritical` had been in the old expression but resolved
  to the same white as every other unread, so it did nothing. Three-state icons follow the workspace dots'
  tones: `Colors.icon.active` for on, `Colors.icon.inactive` for present but
  idle, `Colors.icon.disabled` for off — which is also how bluetooth stopped
  showing the "off" glyph whenever it was merely unconnected.
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

**Nothing the panel draws may wait on the network.** A fetch is a CalDAV REPORT
per calendar — nine here, measured between one and six seconds — so the panel
is built to never need one:

- *The fetched window is far wider than the visible one.*
  `CalendarService.prefetchDays` pads the visible range by 120 days on each
  side and snaps the result to whole months. Snapping matters: unsnapped, the
  edges wobble with the day of the month and paging three months out missed
  coverage by a single day. One fetch now covers roughly −3 to +4 months of
  paging, and `covers()` turns every month change inside it into no work at all.
- *The last answer lives on disk.* `Quickshell.statePath("calendar-cache.json")`
  holds the raw helper payload plus the window it covered, so a freshly started
  shell draws a populated month immediately and only goes to the network when
  `staleAfter` has passed. What is stored is exactly what the helper printed —
  no second format to keep in step.
- *Activation goes through the debounce, not around it.* The panel's `active`
  binding lands a moment before its `rangeStart`/`rangeEnd` bindings, so
  fetching straight from `onActiveChanged` spent the first request on the
  default range and then immediately repeated it. `syncWanted` carries the
  staleness decision into `rangeDebounce` so the first open costs one fetch.
- *A queued re-fetch is re-checked, not forced.* `refetchWanted` re-enters
  `refresh(false)`; forcing it meant the fetch that had just finished could not
  satisfy the request it had already covered, which loops.

Measured after this: cold start with no cache, one fetch; reopening, none;
restarting the shell with the cache on disk, none; clicking five months forward,
one — at the month that actually left the window.

**Event colour comes from the calendar, under Apple's namespace.** Nextcloud
stores it as `calendar-color` in `http://apple.com/ns/ical/`; there is no DAV:
or caldav: equivalent, so that namespace is in the PROPFIND whether or not it
looks out of place. It arrives as `#rrggbbaa` and is cut to `#rrggbb` —
QML reads a 4-byte hex as `#aarrggbb` and would silently shift every hue. A
calendar with no colour set yields `""`, which the panel reads as "use
`Colors.calendar.event`". The agenda shows it as a dot rather than by tinting
the time, because several of these colours are too dark to read as text on the
panel's own background.

**The per-calendar REPORTs overlap, but only four at a time.** Sequentially the
nine here took about 3.4s of the wall time; overlapped, roughly 1.3s. At eight
in flight the server began failing TLS handshakes outright, so
`MAX_PARALLEL_CALENDARS` is 4 — a fetch that half-fails is worse than one that
takes a second longer. Since one calendar can now fail on its own, `collect()`
returns what it did get plus the names it lost, and only raises when every
calendar failed; the helper's `ok` payload carries that note in `message`.

A panel shown by a dropdown zone declares two properties, which are the whole
contract:

- `readonly property bool wantsKeyboard` — raises keyboard focus only for a
  panel with something to type into;
- `readonly property int preferredHeight` — what its content adds up to, which
  the owning surface clamps. Compute it from intrinsic sizes (`contentHeight`,
  `implicitHeight`), never from the panel's own `height` — that is a layout loop.

**The calendar's settings split by sensitivity, not by convenience.** The server
address and the login name are not secrets, so the calendar panel takes them —
`CalendarSetup` when `CalendarService.status` is `unconfigured` — and keeps them
in `Quickshell.statePath("nextcloud.json")`. They reach
`nextcloud-calendar.py` through `Process.environment`, which merges into the
inherited environment rather than replacing it, so a `NEXTCLOUD_URL` already
exported from a shell profile still works for anyone set up that way.

The **app password never touches QML, the state file or argv**. The helper still
reads it from the keyring itself (`secret-tool lookup service nextcloud username
<user>`), and the panel's job is only to say so. Because that password goes out
as HTTP **Basic** auth on every request, both `configure()` and the helper's
`read_config()` refuse an address that is not `https://` — the UI so you find out
while typing, the helper because it is the thing that actually sends it.

`baseAddress()` reduces whatever page got pasted — `/apps/calendar`,
`/settings/user`, `/index.php/...`, a `/remote.php/dav/...` link, a `/u/<id>`
profile — back to the address the DAV endpoints hang off, keeping a subpath
install (`https://host/nextcloud`) intact. This is not a nicety: a stored base of
`https://host/apps/calendar` makes every DAV request 405, and pasting the page
you are looking at is exactly what people do.

**Signing in goes through Login Flow v2** (`services/nextcloud-login.py`), which
is the only thing that works for an account behind an SSO provider. Such an
account has no password to type, and its Nextcloud user id is usually not the
name it signs in with — authentik's own Nextcloud guide maps the user id from
`sub`, i.e. a UUID. The flow sidesteps both: `POST /index.php/login/v2` returns a
browser URL and a poll token, the browser does the authenticating (SSO included),
and the server answers with the real `loginName` **and** a fresh app password.

The password is piped straight to `secret-tool` on stdin — never printed, never
in argv, never returned to QML — so the "credentials stay out of QML" rule
survives the panel growing a login button. The device shows up in Nextcloud as
"Quickshell calendar" under Settings → Security, which is where it gets revoked.

**The calendar home is discovered, not assumed.** It used to be
`/remote.php/dav/calendars/<what you typed>/`, which quietly assumes your
Nextcloud user id is your login name. That holds for a locally created account
and fails for plenty of others: an SSO-provisioned one (Authentik and friends)
often has a UUID for an id, Nextcloud accepts an email address at login, and a
display name is not a login at all. One PROPFIND for `current-user-principal`
against `/remote.php/dav/` answers it, and the id comes back already
percent-encoded — only the login-name fallback needs quoting.
`tests/nextcloud-principal-test.py` covers the parse and the transport guard.

Note what this does *not* fix: the Basic auth username still has to be a real
login. A 401 already says "wrong user or app password", which is the honest
answer when someone types their display name.

## The quick-settings pager

Battery, Wi-Fi, Bluetooth, Audio and Brightness do **not** own popups. The pages
live in `panels/QuickSettingsPanel.qml`, which is shown by two surfaces: the bar,
through the thin `QuickPager` wrapper that `BarContent` owns per screen, and the
right zone of the three-finger dropdown. Adding a page means a panel in
`panels/`, a `page*` index and a `Component` in `QuickSettingsPanel`.

Paging is a **two-finger swipe**, i.e. horizontal wheel events, not a drag.
Measured on this touchpad, one swipe is ~83 wheel events summing to ~17500 of
`angleDelta.x`, so a per-event threshold is useless -- at the original step of
120 a single swipe advanced 146 pages.

The other extreme is just as bad, and was shipped for a while: committing **one
page per gesture** meant a 1001ms swipe of 83 events paged once, 37ms in, and
then did nothing for the remaining 964ms — and the next page had to wait for
`swipeIdle` on top of that. Crossing two pages took two deliberate swipes with a
full stop between them, which is what "sluggish" meant.

So there are **two thresholds**. The first page of a gesture lands at
`Style.pager.swipeStep` (400, about two real events, so a flick is instant);
every page after it inside the same gesture costs `Style.pager.swipeRepeat`
(10000) of further travel, and the accumulator resets on each page.
`swipeIdle` (180ms of no wheel) ends the gesture and restores the cheap first
step. That terminator is the one soft spot: wheel timing is all there is to go
on, so a stall longer than `swipeIdle` in the middle of a real swipe looks like
a gesture boundary and grants one extra cheap page. Seen once in about ten
replays, on a loaded machine; five back-to-back replays of the same gesture all
paged exactly twice. Raising `swipeIdle` would harden it at the cost of merging
genuine quick double-flicks into one gesture, which is the sluggishness this was
fixing, so it stays at 180ms. Replaying the measured gesture through a virtual pointer: a 3180-travel
flick pages once, the real 17596-travel swipe pages twice (at 8ms and 404ms),
and a 42400-travel drag walks all five pages. Those two numbers are the dials if
it wants to feel different.

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

The slide itself is `highlightMoveDuration`, and it is honest: logging
`PathView.offset` showed frames from +8ms to +121ms on `Style.animation.normal`
and +10ms to +81ms after moving it to `Style.animation.fast`. That is the whole
transition cost — the threshold crossing takes about two wheel events (~16ms) on
top.

It is a `PathView`, not a `ListView`, because it wraps: swiping left from the
first page lands on the last, so no page is more than two swipes away. There is
no `SwipeView` because nothing in this project imports `QtQuick.Controls`, and
that is worth keeping.

**`PathView` spacing is path length divided by `pathItemCount`, not the delegate
width.** With `pathItemCount: 3` the path must be three page-widths long
(`-width` to `width * 2`) or the pages overlap and you see two panels drawn on
top of each other. A path of `-width/2` to `width * 1.5` spaces them two thirds
of a page apart and looks like a rendering bug.

Padding belongs to the pages, not the pager: `QuickPager` fills its chrome with
`QuickSettingsPanel` at zero margin, so the `PathView` reaches the border and a
page slides in from the true edge. The page indicator sits `Style.bar.padding`
above the bottom border, matching the frame the pages draw, and each dot's
`MouseArea` is grown by `-Style.widgets.spacing` because a 6px target is not
clickable.

`cacheItemCount` keeps all five delegates alive so a page keeps its state while
you swipe past it. That means a panel is constructed whether or not it is
showing, so anything expensive must be gated on being the current page —
`WifiPanel.active` is bound to `root.visible && pages.currentIndex === pageWifi`
so scanning only runs while it is on screen.

## The volume/brightness OSD

`osd/Osd.qml` owns the five media keys and shows the reading itself. It replaced
**swayosd**, which was a whole daemon running for nothing else. Hyprland binds
the keys to `hl.dsp.global("quickshell:volumeUp")` and friends, matching the
`GlobalShortcut` names in that file, the way the launcher and lock already work.

- Volume goes straight through Pipewire (`PwNode.audio.volume`), no process at
  all. Brightness goes through `Brightness`, which now calls **`brightnessctl`**
  — it reaches the backlight over logind, so it needs no `video` group
  membership (`alice` is not in it) and no daemon.
- `Brightness.minimum` (5%) mirrors the floor swayosd used to enforce, so the
  slider still cannot black the screen. Without it the OSD and the slider would
  happily go to 0.
- The window is **input-transparent**: `mask: Region {}` is empty, so every
  click, scroll and keystroke over it goes to the window underneath, and
  `keyboardFocus` is `None` with no `HyprlandFocusGrab`. This is not cosmetic —
  an OSD that takes pointer or keyboard focus on every volume keypress would
  break whatever you were typing into. Verified against a control: with
  `mask: Region { item: panel }` the same cursor walk produced hover events,
  with the empty region it produced none.
- It reuses `AudioPanel` and `BrightnessPanel` unchanged and sizes itself to
  their `preferredHeight`, so it is the same chrome as the dropdown, just
  shorter. The namespace is `quickshell:osd-popup`, which the existing
  `^quickshell:.*-popup$` layer rule already blurs.

**The OSD and the quick-settings surfaces never show at once**, because they draw
the same panels into the same corner and stacked up when you pressed a media key
and then pulled the dropdown down. `OsdState` (a singleton, so both sides can see
it) arbitrates:

- `viewers` counts quick-settings surfaces on screen. `QuickSettingsPanel`
  maintains it from its own `active` property, which is the one thing both hosts
  already set correctly, so the dropdown and every bar `QuickPager` are covered
  by one piece of code. It is written through an idempotent `syncViewer()` with a
  `counted` mirror, because the dropdown's `Loader` destroys the panel while
  `active` is still true and a naive increment/decrement pair leaks a count.
- While `viewers > 0` the OSD does not show; the key still changes the value, and
  the open panel shows it live.
- `zone` and `zoneAt` record which readout was last touched. A dropdown opening
  within `OsdState.timeout` of that calls `pageFor(zone)` and starts on that
  page, so pulling down straight after a volume key continues on Audio instead
  of stacking a second copy of it. The check is a **timestamp**, not
  `showing` — opening the dropdown sets `viewers` first, which clears `showing`
  before the panel is even constructed.

The reverse holds too: a media key pressed while a surface is already up turns it
to that page (`followOsd()`, on a `Connections` watching `zoneAt` so a second
press of the same key still counts). Changing a value that is not on screen is
the worse outcome — you only reach for those keys deliberately.

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
`CalendarService.eventsByDay`) *or* declares the element type —
`: list<color>` on `CalendarPanel.dotColours()` satisfies both the engine and
the linter, where a bare `: var` crashes one and no annotation at all makes the
other log per call site; the three files with an `IpcHandler` need `: void` and
are excluded from linting.

**A full-screen overlay is already positioned below the bar's exclusive zone.**
The compositor hands such a window the screen minus every reserved strip, so its
y=0 is under the bar — adding the bar height to a top margin counts it twice.
Its x=0 *is* the screen's left edge, while `QsWindow.itemRect()` reports in the
item's own window frame; the bar's window starts `Style.bar.sideGap` in, and
`QsWindow` exposes no absolute position, so that token reconciles the two.

**`sideGap` is where the bar's *window* starts; `edgeGap` is where the bar
*looks* like it starts.** `BarContent` fills that window inset by one border
width, so the frame the eye follows sits at `sideGap + Style.border.width`.
Every surface that floats under the bar — both dropdown zones, `WidgetPopup`,
the OSD, the toasts — lines up on `Style.bar.edgeGap` for that reason. Using
`sideGap` puts them a pixel wide of the bar on each side: not enough to name,
exactly enough to notice. `measureAnchor()` is the one place that still wants
`sideGap`, because `itemRect()` already counts the border in its `x`.

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

**A polled value must not be the thing the UI reads back after a write.** The
brightness slider felt broken — measured, the fill stayed put for **930ms** and
then jumped. Nothing was slow except the round trip: `swayosd-client` moves the
real backlight in ~22ms (exec to sysfs), but `Brightness.level` only refreshed
on its 1s poll, so the UI waited for the next tick. `Brightness.request()` now
sets `level` to the requested value immediately and holds off sysfs reads for
`settleInterval` (250ms, an order of magnitude over the 22ms the write needs),
after which the poll reasserts whatever the hardware actually did. That makes it
self-correcting: a failed write shows the truth again one tick later.

Two consequences worth knowing:

- Writes are throttled to one per `writeInterval` (50ms). A drag emits a request
  per pointer event — ~123/s on this touchpad — and each one was spawning a
  process. The throttle writes on the leading edge, then at most once per
  interval while requests keep arriving, so the click stays instant and the
  final position is always sent. Measured 23 writes/s across a 733ms drag.
- `adjust()` sends an **absolute** percentage now, not `+5`/`-5`. Relative
  writes cannot be coalesced — dropping one drops a step — while absolute ones
  compose correctly, because `request()` has already moved `level`.
- swayosd's own `min_brightness` (5 here, in `~/.config/swayosd/config.toml`)
  clamps absolute values too, so the slider cannot black the screen. Dragging
  below it shows the requested value for a beat before the poll corrects to 5%.

**Reconfiguring a layer surface kills its `HyprlandFocusGrab`.** The dropdown
set `WlrLayershell.keyboardFocus` from the current page
(`Exclusive` for Wi-Fi, `OnDemand` otherwise). Swiping to the Wi-Fi page
therefore reconfigured the surface, Hyprland re-evaluated focus, the grab
cleared, and `onCleared` dismissed the whole dropdown ~180ms later — the page
was unreachable. **Keep `keyboardFocus` static for the lifetime of a window.**
`OnDemand` is enough for text input: the launcher has always typed fine on it,
and so does the Wi-Fi PSK field (verified — three characters typed from a uinput
keyboard landed in the field, and Escape dismissed the prompt without closing
the dropdown). Nothing needed `Exclusive`, so `wantsKeyboard` is gone from every
panel.

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
