# Project structure — agent reference

Working notes for Claude Code sessions on `config/quickshell/`. Rules for how
to write code here live in `config/quickshell/llm.md`; this file is the map and
the list of things that have already cost a bug. Colour, wallust templating and
Qt/KDE theming are in `.github/THEMING.md`.

Installed: **Quickshell 0.3.1**, **Hyprland 0.56.2**, Arch Linux, Qt 6.

## Layout

```
config/quickshell/
├── shell.qml              Entry point: Bar, Dropdown, Launcher, Lock, Toasts,
│                          Osd and the Settings app.
├── llm.md                 Coding rules for agents.
├── style/                 Colors.qml, Style.qml — every colour and dimension —
│                          and Theme.qml, the palette Colors derives from.
├── services/              Singletons: data sources + cross-surface state.
│                          Brightness, CalendarService (+ nextcloud-calendar.py),
│                          DisplayChange, DropdownState, LauncherHistory,
│                          LockService, NotificationService, OsdState,
│                          PopupAreas, QuickToggles (+ screen-record.sh),
│                          Screens, SettingsState, SystemUsage, Time, Volume,
│                          WallpaperService (+ wallpaper-import.sh),
│                          WorkspaceBlocks.
├── panels/                Panel content shown by more than one surface:
│                          AudioPanel, BatteryPanel, BluetoothPanel,
│                          BrightnessPanel, CalendarPanel, ClipboardPanel,
│                          NotificationPanel (+NotificationEntry), SystemPanel,
│                          TogglesPanel (+ToggleTile), WifiPanel, WorkspacePanel;
│                          and what they are built from: PanelFrame (a panel's
│                          chrome), PillButton and PillGroup (the design's
│                          switches), TextButton (a word or glyph to click),
│                          SliderRow and VolumeRow, DetailRow, PanelSlider,
│                          InputField, WallpaperCard.
├── bar/                   Bar.qml (PanelWindow per screen) + BarContent.qml,
│   │                      and BarDrawer.qml (the right side's hidden icons).
│   └── widgets/           one file per widget, plus WidgetPopup.qml (the
│                          shared dropdown shell), QuickPager.qml (the swipeable
│                          quick-settings dropdown), PowerAction.qml, and
│                          TrayMenu.qml + TrayMenuItem.qml.
├── dropdown/              Dropdown.qml — one overlay for all three swipe zones
│                          (workspaces, calendar, quick settings).
├── notifications/         Toasts.qml (the popup stack window) + Toast.qml.
├── launcher/              Launcher.qml (scope/IPC/shortcut) + LauncherContent.qml.
│                          The Figma file's "Search Box" is not built: the owner
│                          kept this fullscreen launcher instead (27 September).
├── lock/                  Lock.qml (WlSessionLock) + LockSurface.qml (per monitor).
└── settings/              SettingsApp.qml (scope/IPC/shortcuts/window) +
                           SettingsContent.qml (sidebar, page host), the pages
                           (Appearance, Displays, Sound, Network, Bluetooth,
                           Notifications, Power, Keybinds, Startup, Wallpaper
                           with WallpaperGrid and ThemeGrid, About), the parts
                           they share (Card, PanelCard, ScrollPage, Section,
                           ActionRow, ChoiceField, KeyCap, ThemeCard) and their
                           helpers: displays.py, autostart.py, startup-list.lua.
```

## Import graph

`style/` and `services/` are leaves — they import nothing from this project.
`panels/` imports those two only. `bar/`, `dropdown/`, `launcher/`, `lock/`,
`notifications/`, `osd/` and `settings/` sit on top and may import any of the
three. It is a DAG, deliberately:

- **Shared state goes down into `services/`.** `DropdownState` and `LockService`
  live there because the bar's clock and workspace dots open dropdown zones and
  the bar's power menu raises the lock. State next to the window it drives
  would make `bar/widgets` import `dropdown/`/`lock/` while they imported it
  back.
- **Shared content goes into `panels/`.** A panel is the inside of a dropdown
  with no opinion about which surface shows it; several Settings pages are
  quick-settings panels in a card (`settings/PanelCard`). The quick-settings
  pages are shown by the bar's pager and the dropdown's right zone; the
  workspace and calendar panels only by the dropdown, which the bar's dots and
  clock open. What only the Settings app shows lives in `settings/`.

Nothing in `bar/` may import `dropdown/` or `lock/`.

**`style/` is also the greeter's.** `scripts/install-greeter.sh` copies it into
`/etc/greetd`, where it runs as a user that cannot read `$HOME` and may have no
writable home of its own. That is why `Theme.qml` lives in `style/` (Colors has
to reach it without importing `services/`, which the greeter does not get) and
why it must only ever read until a theme is picked: no process at construction,
and no `Quickshell.statePath()`, which creates its directory the moment it is
called and logs an error where it cannot. Checked by loading the style folder
alone with `HOME=/nonexistent`: default colours, nothing spawned, no error.

The monitor layout is shared the same way: `etc/greetd/monitors.lua` is a
symlink to `config/hypr/modules/monitors.lua`, which the greeter's compositor
config `require`s and the script installs as a copy. That config used to carry
the laptop's panel alone, so on the desktop both outputs came up unconfigured.
`tests/install-greeter-test.py` stages an install and fails on any symlink left
in it: copied as one, monitors.lua dangles and the config dies at `require`.

## Conventions

- **Formatting is Qt 6's `qmlformat`, i.e. the official Qt QML conventions.**
  Run `scripts/check.sh --fix`; the pre-commit hook does it for staged files.
  The earlier house style (a `// path/File.qml` header on line 1, no comments,
  blank lines between property groups) was dropped: it was a stand-in for a
  real standard and it fought the formatter.
- **`check.sh` puts `/usr/lib/qt6/bin` first on `PATH`.** `/usr/bin/qmlformat`
  and `qmllint` are Qt 5's (`qt5-declarative`, `qmllint --version` says 1.0).
  Until 28 September the tree was formatted with them, which is where `return
  ;`, blank lines before a closing brace, quoted object keys and every arrow
  function spelled `x => { return y; }` came from, and why `: void`, typed
  lists and the spread operator looked unusable (Qt 5's parser rejects them)
  and `1048576` came back as `1.04858e+06`. Qt 6's tools handle all of it;
  write `x => y`.
- **Members stay in the order written**: id, properties, signals, functions,
  object properties, children. qmlformat keeps it; `qmlformat --normalize`
  would sort bindings alphabetically instead, so it is not used.
- **`pragma` goes on line 1**, as Quickshell's docs ask; qmlformat puts it there.
- Every imported folder has a `qmldir` declaring its types explicitly
  (`BluetoothWidget 1.0 BluetoothWidget.qml`, `singleton Time 1.0 Time.qml`).
  Required for `pragma Singleton`; done everywhere else for consistency.
- **Every panel in `panels/` is a `PanelFrame`**, which owns the padding and the
  chrome: a header of `Style.popup.itemHeight` with the title and, at its
  right, whatever the panel puts in `trailing`, a one-pixel separator, then the
  content; a panel's `implicitHeight` is `chromeHeight` plus its content's.
  Hosts (the dropdown's `Loader`, `QuickPager`) add no margins of their own, so
  a page looks identical in either surface and the pager slides pages edge to
  edge. Panels written without this frame had their titles on the rounded
  corner and every title at a different height as you swiped. The calendar is
  the one panel with a header of its own (month and chevrons).
- **The design's switches are `PillGroup`s**: `choices` of `{label, value}`,
  Off and On unless given, `current`, `picked(value)`; given a width they wrap,
  or with `fill` share it out. A word or a glyph to click (Clear, ×, Forget,
  the gear) is a `TextButton`, muted until hovered, its target grown past its
  edges. A volume or brightness row is a `SliderRow` (`VolumeRow` for a
  PipeWire node).
- **Glyphs are written as `"\u{F0141}"` escapes, never pasted**; `check.sh`
  fails on a pasted private-use character (see "Private-use glyphs" below).
- **One icon family across the bar, and one rule for colour.** Every glyph is a
  Material Design one from the Nerd Font (`nf-md-*`, the U+F0000 plane) at
  `Style.text.iconSize`, wrapped in `implicitWidth: row.implicitWidth +
  Style.widgets.padding * 2` so the row spaces evenly. The right-hand side used
  to break this three ways: the notifications bell was Font Awesome
  (`\uf0f3`), the battery was a hand-drawn `Rectangle` pill rather than a
  glyph, and volume was the only icon carrying a percentage. **Every icon is
  `Colors.icon.active`**, in the bar and in the panels alike; on, idle and off
  are told apart by the glyph alone (bell / bell-off / bell-outline, the Wi-Fi
  ramp / wifi-off, bluetooth / bluetooth-connect / bluetooth-off). The grey
  tones that used to mark idle and off were unreadable over a light wallpaper,
  where the translucent bar turns mid-grey. The only other colour is attention:
  `UsageMeter` turns orange past `Style.usage.warnAbove`, a battery goes orange
  at 20% and red at 10%, and the bell is `Colors.notification.urgent` while
  something critical waits (unless Do Not Disturb is on). The workspace dots and
  the pager's page dots keep their dim tone, because they are position
  indicators rather than icons and have no glyph to carry state instead.
- **Colours are derived from a theme, not written down.** `Colors.palette`
  holds eight inputs (background, foreground, and the ANSI red, green, yellow,
  blue, purple and cyan slots) and every other colour is computed from them:
  `text.muted` is 58% of the way from background to foreground, `base.border`
  35%, hovers and pills are the foreground at low alpha. The inputs come from
  the theme wallust rendered (see "Themes" below); without one they are the
  colours the shell was designed with, and the formulas reproduce the old
  literals exactly (`#9a9a9a`, `#646464`, `#0b0b0b` — checked). So a new colour
  is a formula over the palette, and a literal only where the theme must have
  no say: `Colors.overlay` for anything drawn over a picture under a dark scrim
  (wallpaper card labels, the lock screen), which stays light-on-dark under a
  light theme.
- 4-space indent, no tabs (`.editorconfig`).
- PascalCase files, camelCase ids and properties, typed properties over `var`.

## Where things go

| Adding | Goes |
| --- | --- |
| A colour | `style/Colors.qml`, in the feature group, derived from `Colors.palette`; over a picture, from `Colors.overlay` |
| A spacing/size/radius/font value | `style/Style.qml`, same grouping |
| A bar widget | `bar/widgets/` + its `qmldir` + a place in `BarContent.qml`; on the right, either an always-visible row or the `BarDrawer` |
| A widget dropdown | wrap it in `WidgetPopup` — never hand-roll another catcher window |
| A panel | a `PanelFrame` in `panels/` with `title`, `trailing` and an `implicitHeight` |
| A quick-settings page | a panel in `panels/` + a `page*` index and `Component` in `QuickSettingsPanel` |
| A panel shown by two surfaces | `panels/`, importing only `services/` and `style/` |
| A new swipe zone | a panel, a zone name in `DropdownState` and its place in `step()`'s order, a `Component` in `Dropdown.qml` |
| Anything fetched from outside | a `services/` singleton, with a helper script run through `Process` |
| A new top-level surface | its own folder + `qmldir`, following `launcher/` for an overlay or `settings/` for an ordinary window |
| A Settings page | an entry in `SettingsContent.pages` (name, title, glyph, search words) and a `Component` in its `Loader`; a page taller than the window is a `ScrollPage`; a quick-settings panel goes in a `PanelCard`, a group of rows in a `Card`, a note with its action under a list in an `ActionRow` |
| A switch between a few values | a `PillGroup` |
| Something that has to run from login | a `services/` singleton with an `active` flag, bound to true by whatever is always built (the `WallpaperService` binding in `SettingsApp.qml`) |
| A popup-like surface in the top right | publish what it covers with `PopupAreas.set()` (as `WidgetPopup` and `Dropdown` do), so toasts move below it |

A widget that needs to know its monitor (for `Hyprland.monitorFor()`, or so its
popup opens on the right screen) declares `required property ShellScreen screen`
and gets it passed down from `BarContent.qml`, which gets it from `Bar.qml`'s
`PanelWindow.screen`.

`WidgetPopup` usage: set `anchorItem: root` so it opens under its own widget, a
distinct `namespaceSuffix`, and put content as default-property children. See
`PowerWidget.qml`. Leaving `anchorItem` unset puts the popup at the right edge
instead, on `Style.bar.edgeGap`; the notification centre is the one popup that
does this (see Notifications).

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
- `implicitHeight` — what its content adds up to, which the owning surface
  clamps and reads as its `Loader`'s `implicitHeight`, typed, instead of
  reaching into `item`. Compute it from intrinsic sizes (`contentHeight`,
  children's `implicitHeight`), never from the panel's own `height` — that is a
  layout loop. Text makes it fractional, so whatever sets a `height` from it
  rounds it down (`Math.floor`): a frame ending mid-pixel blurs its bottom
  border across two rows. It was an `int` property until 28 September, which
  did the rounding silently.

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

Battery, Wi-Fi, Bluetooth, Audio, Brightness, Toggles and Clipboard do **not**
own popups.
The pages live in `panels/QuickSettingsPanel.qml`, which is shown by two
surfaces: the bar, through the thin `QuickPager` wrapper that `BarContent` owns
per screen, and the right zone of the three-finger dropdown. Adding a page means
a panel in `panels/`, a `page*` index and a `Component` in `QuickSettingsPanel`.

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

`cacheItemCount` keeps every delegate alive so a page keeps its state while
you swipe past it. That means a panel is constructed whether or not it is
showing, so anything expensive must be gated on being the current page —
`WifiPanel.active` is bound to `root.visible && pages.currentIndex === pageWifi`
so scanning only runs while it is on screen, and `BluetoothPanel.active` the
same way for its search.

## Arrow keys

Left and right move to the next dropdown. The gesture dropdown is a strip in
the order its zones sit on screen — workspaces, calendar, then the seven
quick-settings pages — and `DropdownState.step()` stops at either end rather
than wrapping, since the ends are the edges of the screen. The pages are steps
of their own: `QuickSettingsPanel.step(direction, wrap)` pages, and with `wrap`
off returns false at the first and last page, which is the dropdown's cue to
change zone. The bar's pager has nowhere else to go, so it wraps like a swipe.
It hears the keys through `WidgetPopup.arrowPressed`, which every popup emits
and only `QuickPager` handles.

The bar's workspace dots open the dropdown's workspace zone instead of a popup
of their own, as the clock opens the calendar zone, so the strip is the same
however it was opened. The two already looked identical: same width, same x
(the dots sit at the bar's left edge, where `WidgetPopup` clamps to `edgeGap`),
same blur.

**A text field keeps its arrows.** `TextInput` lets Left through at the start
of its text and Right at the end, and both when it is empty. Unguarded, the
Left after the first character walked the dropdown to the next zone and threw
away the field and what was typed in it (reproduced in the calendar's setup
fields). Both hosts check `Window.activeFocusItem instanceof TextInput` first —
not "the scope has focus", because once a field lets go, active focus stays on
the nearest `Loader`.

## The volume/brightness OSD

`osd/Osd.qml` owns the five media keys and shows the reading itself. It replaced
**swayosd**, which was a whole daemon running for nothing else. Hyprland binds
the keys to `hl.dsp.global("quickshell:volumeUp")` and friends, matching the
`GlobalShortcut` names in that file, the way the launcher and lock already work.

- Volume goes straight through PipeWire (`PwNode.audio.volume`), no process at
  all, in `services/Volume`, which the bar's volume icon uses too (step,
  unmute on change, mute toggle). Brightness goes through `Brightness`, which
  calls **`brightnessctl`** — it reaches the backlight over logind, so it
  needs no `video` group membership (`alice` is not in it) and no daemon.
- `Brightness.minimum` (5%) is a floor, so the slider cannot black the
  screen.
- The window is **input-transparent**: `mask: Region {}` is empty, so every
  click, scroll and keystroke over it goes to the window underneath, and
  `keyboardFocus` is `None` with no `HyprlandFocusGrab`. This is not cosmetic —
  an OSD that takes pointer or keyboard focus on every volume keypress would
  break whatever you were typing into. Verified against a control: with
  `mask: Region { item: panel }` the same cursor walk produced hover events,
  with the empty region it produced none.
- It reuses `AudioPanel` and `BrightnessPanel` unchanged and sizes itself to
  their `implicitHeight`, so it is the same chrome as the dropdown, just
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

## Quick toggles

The design file's tray flyout is the sixth quick-settings page (the seventh is
the clipboard history, below),
`panels/TogglesPanel.qml`: a grid of `ToggleTile`s. The bar opens it from
`TogglesWidget`, the design's "More (expand)" dots beside the tray, through the
same `QuickPager` as every other page, so the dropdown's right zone has it too.
The state lives in `services/QuickToggles.qml`.

| Tile | Backend |
| --- | --- |
| Do Not Disturb | `NotificationService.doNotDisturb`, the flag right-clicking the bell flips |
| Airplane Mode | `Networking.wifiEnabled` and `Bluetooth.defaultAdapter.enabled` |
| Night Light | a `hyprsunset` process the shell owns |
| Screen Record | a `wf-recorder` process the shell owns, stopped with SIGINT |
| Clipboard | two `wl-paste --watch cliphist store` processes (text, images) |
| Caffeine | an `IdleInhibitor` on every bar, enabled while it is on |

**Night Light is a process, not hyprsunset's IPC.** Hyprland resets every
monitor's colour matrix when the ctm-control client that set it disconnects
(`~CHyprlandCTMControlResource`), so stopping hyprsunset *is* the off switch and
there is no daemon state to keep in step. Hyprland also allows only one CTM
manager: a second hyprsunset is sent `blocked` and exits 1.

That second rule is why it runs under `setpriv --pdeathsig TERM`. Measured in a
nested Hyprland, a SIGTERM'd `qs` left its hyprsunset running under
`systemd --user`, still tinting, and the restarted shell's own hyprsunset was
then blocked, so the tile read off over a warm screen with no way to clear it.
With the parent-death signal, SIGTERM and SIGKILL both take it down with the
shell, a restart brings it back from the saved state, and five reloads in a row
each restarted it cleanly.

- What persists is the choice, in `Quickshell.statePath("quick-toggles.json")`.
  The tile shows whether the process is actually running, so a hyprsunset you
  started yourself shows up honestly: it blocks the shell's, the tile stays off,
  and the log says `night light: hyprsunset exited with status 1`.
- The tint is applied after screen capture, so a screenshot never shows it.
  Check it with `hyprctl hyprsunset temperature`, which answers `4000`.
- **The bar is what constructs `QuickToggles`**, through the dots' glyph
  binding. A singleton is built on first use, and that construction is what
  restarts Night Light at login, so keep something on screen reading it.

**Airplane Mode goes through NetworkManager and BlueZ, not rfkill.** It is on
when Wi-Fi and Bluetooth are both off, however they got that way, and switching
it off turns both back on. rfkill would have needed a long-running
`rfkill event` watcher, and it would disagree with the Wi-Fi page's On/Off
header, which writes the same `Networking.wifiEnabled`.

**Caffeine keeps the session awake.** A left click switches it on or off, and a
right click cycles the length: 15 min → 30 min → 1 h → 2 h → no limit. Off,
the label says the length a click gives; on, the time it ends ("until 16:40").
It is an `IdleInhibitor` on every bar (`bar/Bar.qml`), as an inhibitor needs a
window, and hypridle's idle notifications respect inhibitors, so neither the
lock nor the screens going off come while it is on. A length starts at the
clock's next minute and ends on its ticks (`Time.now`, the wall clock), so it
lasts at least what it says and at most a minute more, and a suspend in between
does not stretch it. Only the length persists (`caffeineMinutes`): a new shell,
a reload included, starts with it off and locks as usual.

Hyprland (0.56) weighs an inhibitor on a layer surface when it arrives, and one
that arrives before its surface is mapped does nothing. Measured in a nested
Hyprland with a bar-like `PanelWindow` and two `IdleMonitor`s, one of them
ignoring inhibitors: enabled at start, the inhibitor held nothing; enabled two
seconds after the map, it kept the other monitor from idling until it was
switched off, while the one ignoring it went idle. Caffeine only turns on over
bars that are already up. A bar that appears while it is on, for a monitor
plugged in, brings an inhibitor that does not count, beside those that do.

**Power profiles are on the Battery page**, as a compact `PillGroup` with
`fill` under the details, one pill per profile the hardware offers; a click
sets that profile. The pager has that page on a desktop too, and the Settings
app's Power page shows the same row; both take `QuickToggles.profileChoices`.
`PowerProfiles` exposes no availability flag: without the daemon it sits at
Balanced and a pick only logs a critical. It fits without touching the pager's
height: the UPower display device never carries a model or a capacity (both
read `""`/`0` over DBus here), so at most three detail rows show above it.
Checked on screen by switching profiles with `powerprofilesctl set`, which the
selected segment followed.

While Do Not Disturb, Airplane Mode, Night Light, Caffeine or a recording is
on, the dots gain a ring (`md-dots_horizontal_circle_outline`); the icon colour
never changes. Tiles follow the same rule: every glyph and label is full white,
and "on" is the filled badge, whose glyph turns `Colors.text.inverted` to stay
readable on it. Six tiles, three to a row, is the design's grid; a label wraps
to two lines rather than elide, since the dropdown's zone is 320 wide and
"Do Not Disturb" at three to a row is not (`Style.toggles.tileHeight` is 76 for
that, which still fits the pager's page area).

**Screen Record** runs `services/screen-record.sh` on the focused monitor: it
prints the file it records to (`<videos>/Recordings/<date>.mp4`, with
`xdg-user-dir VIDEOS`, and `~/Videos` where that is `$HOME`, which is how
xdg-user-dirs marks a folder it was told not to have) and execs `wf-recorder -o
<monitor>` under `setpriv --pdeathsig INT`: a recording nobody could stop would
run until the disk is full. The tile sends SIGINT (`Process.signal(2)`), which
wf-recorder takes as "finish the file"; the saved file is announced with
`notify-send`, i.e. by the shell's own notification server. Flushing the
encoder takes wf-recorder a second or two after SIGINT, and the tile reads
"Recording" until it exits, i.e. until the file is complete.

**Clipboard** is history, not the clipboard itself: the tile starts or stops
the two watchers, persisted like Night Light and honest the same way. They
check for cliphist first, because `wl-paste --watch` would otherwise run on
with every copy failing unseen and the tile reading on. Its right click
(`ToggleTile.secondaryActivated`) turns the pager to the seventh page,
`ClipboardPanel`: `cliphist list`, read when the page is shown (the pager builds
every page up front) and whenever cliphist's database changes while it is; a
click copies an entry again (`cliphist decode | wl-copy`), `×` forgets it,
"Clear" wipes it all. cliphist's line goes to it on stdin, never through a
shell's quoting. Images read "PNG image, 120×120" rather than cliphist's
`[[ binary data … ]]`.

The database watch is a `FileView` with `preload: false` (so the file is never
read) and `watchChanges` bound to the page being shown, which re-arms the watch
at every showing. Without it the list went stale in two ways: a copy made while
the page was open did not turn up, and an entry copied back moved to the top
under a new id (cliphist deduplicates) while the page kept the old one, whose
second click would have decoded nothing and copied an empty string. Neither
`cliphist list` nor `decode` writes the database, so the watch cannot loop. A
`db-path` set in cliphist's own config is not followed; the page then only
refreshes when shown and after its own changes.

What is not stored: a copy offered as sensitive (`x-kde-passwordManagerHint`,
which KeePassXC sets on passwords, or `wl-copy --sensitive`): wl-paste reports
it as `CLIPBOARD_STATE=sensitive` and cliphist skips it.

Both need their package: `cliphist` and `wf-recorder`. Without them the tiles
stay off and the log says `exited with status 127`. With them, both were driven
by a virtual pointer in a nested Hyprland on 27 September: text and image
copies listed, copied back byte for byte, forgotten and cleared, history
switched off and on from the page header, and a recording started and stopped
into a valid H.264 MP4 with its "Recording saved" toast.

The Toggles page's header has a gear (`md-cog_outline`), the way into the
Settings app from the quick settings.

## The bar's right side

Only the icons worth a glance at any time are always there: the bell, the
toggles dots, battery, power. The tray, brightness, Bluetooth, volume and Wi-Fi
live in `bar/BarDrawer.qml`, a strip between the dots and the battery that is
closed by default; on the desktop, which has no battery, that leaves bell, dots
and power. **SUPER+B** opens and closes it on every screen at once: it is the
`barExpand` `GlobalShortcut` in `Bar.qml`, which owns the one `expanded` flag
that each screen's `BarContent` follows. Right-clicking the dots does the same;
a left click still opens the Toggles page.

**The drawer is anchored between two rows, not placed inside one.** It animates
its width with `Style.animation.slow`, and a `Row` cannot hold an item doing
that: a positioner skips a zero-width child, then adds a full `spacing` the
moment the child grows past zero, so every open and close would start with an
8px jump. So `BarContent` anchors three pieces right to left: the
always-visible `right` row, the drawer against its left edge, and `rightLead`
(the bell and dots) against the drawer with one spacing of margin. The drawer's
width includes one trailing spacing of its own, so a closed drawer leaves
exactly one gap between the dots and the battery and an open one leaves a gap
on each side. Measured: 8px on both sides at rest either way, and a
collapse-expand-collapse cycle ends pixel-identical to where it started.

The drawer's `Row` is anchored to its right edge, so opening it uncovers Wi-Fi
first and the tray last, while the bell and dots move left. Open, the bar reads
exactly as it did before the drawer existed. Volume keeps its scroll-to-adjust
and right-click mute inside it; the media keys never needed the icon.

**Its `clip` is load-bearing.** A closed drawer's widgets sit exactly under the
bell and the dots, and are declared after them, so they would take those
clicks. Clipping a parent blocks pointer delivery to children outside it:
checked with `qmltestrunner` on Qt 6.11, against an unclipped control whose
hidden child did take the click.

A popup already open when the drawer moves stays where it opened, since
`WidgetPopup` only re-measures its anchor when that item's own `x` changes, and
a moving row does not change it.

## The usage dropdown

Clicking the CPU/RAM meters opens `SystemPanel` (`usage-popup`): a bar per core,
the CPU's model, average frequency, temperature and load average, then memory
used, cache (`free`'s buff/cache) and swap, with the uptime in its header.

- **Only what the meters need is read all the time.** `/proc/stat` and
  `/proc/meminfo` were read every 3s already; the per-core shares and the extra
  memory fields come out of those same reads, so an opening panel has a real
  sample at once. `/proc/cpuinfo`, `/proc/loadavg`, `/proc/uptime` and the
  sensor are read only while `SystemUsage.detailed` is set, which the panel
  binds, and the interval drops to 1s for as long as it is.
- **The sensor is found by its driver's name**, once, on first open: hwmon
  numbers follow probe order and change between boots (`k10temp` is `hwmon5`
  here today). Tried in order: `k10temp`, `zenpower`, `coretemp`,
  `cpu_thermal`; with none of them the Temperature row stays hidden.
- The model name is shortened for the row: "AMD Ryzen 5 7640U w/ Radeon 760M
  Graphics" shows as "AMD Ryzen 5 7640U", and Intel's `(R)`, `(TM)` and
  "CPU @ …" go the same way.

## Wallpaper & Background

The Settings app's Wallpaper page (`settings/WallpaperPage`) is the only place
wallpapers and themes are chosen: there was a separate wallpaper window as
well, which the owner found redundant and which went on 27 September. **SUPER+W**
opens Settings on this page, and closes it when it is already showing it
(`wallpaperToggle` → `SettingsState.toggle("wallpaper")`); the workspace
dropdown's wallpaper card and Appearance's "Change Wallpaper…" lead here too.

It follows the Figma file's "Wallpaper Selector" frame: 2:1 cards with a label
pill and an applied badge (`panels/WallpaperCard`, which the workspace dropdown
shows too), the category tabs and "APPLY TO: This Workspace / All Workspaces".
Two tabs sit above them, Wallpapers (`WallpaperGrid`) and Themes (`ThemeGrid`,
built the first time it is opened, as it runs palettes.py).

**Wallpapers** are `~/Wallpapers` and its subfolders, one `FolderListModel`
each, all watching their directory, so an import or a new folder shows up by
itself. **The subfolders are the design's category tabs** ("All", then one per
folder, shown once there is one); "All" is the top folder and every subfolder
together. The grid's model is `WallpaperService.library`, a `ListModel` the
service rebuilds from the folder models (they settle one after the other, so
through a 50ms debounce), sorted by name: rotation walks it too, one list, one
order. The tab persists in `wallpaper.json`, and "Add from file…" imports into
the tab's folder. Thumbnails decode at the fixed
`Style.wallpaper.thumbnailWidth` rather than the card's width: the cards follow
the window, and a `sourceSize` bound to them would decode every image again on
each step of a resize.

- **All Workspaces** (the default) sets the one for every workspace:
  `hyprctl hyprpaper wallpaper ",<path>,cover"`, the empty monitor being
  hyprpaper's fallback for every monitor not named, then each monitor by name
  where one already is. It clears every workspace's own: "all" means all.
  About 5ms a call; a missing file exits 1 with `bad path`, shown in the footer.
- **This Workspace** gives the focused workspace one of its own. hyprpaper sets
  a monitor, not a workspace, so the service watches every monitor's
  `activeWorkspace` and names the monitor whenever what it should show changes.
  A workspace is keyed as its monitor and number, `DP-2:3`, from
  `workspace-blocks.json` (see "Workspaces per monitor"): its id differs from
  session to session. The keys persist in `wallpaper.json`. Once hyprpaper has
  been told a monitor by name, the fallback no longer reaches it, so from then
  on that monitor is always named; a monitor never named is taken to show the
  fallback, which is also why the shell sends nothing at start unless some
  workspace has its own. Tested in the nested session: workspace 1 on its own
  wallpaper, 2 on the fallback, back and forth (`hyprctl hyprpaper listactive`),
  then All Workspaces clearing it.
- **The choice persists as a hyprpaper config of its own**,
  `$XDG_STATE_HOME/quickshell/hyprpaper.conf`: it `source`s hyprpaper.conf,
  then declares its own wallpaper block. hyprpaper keys the block by monitor,
  so the later one for the same (empty) monitor overrides the earlier one —
  checked. `modules/startup.lua` starts hyprpaper with `-c` on it when it exists.
  It cannot be the other way round, a `source =` in hyprpaper.conf: hyprpaper
  0.8.4 refuses to start at all when a sourced file is missing (`source= path
  error`, exit 1), and its glob support fails the same way, because it
  canonicalises the path before globbing it.
- **`fit_mode` is `cover` everywhere.** In hyprpaper 0.8 `fill` is *stretch*,
  which distorts a 16:9 image on the laptop's 3:2 panel, and the IPC cannot
  express stretch at all: hyprctl reads `fill` as cover, and sends stretch as
  "fit", which hyprpaper's own parser does not know and turns into cover.
  hyprpaper.conf was moved to `cover` so login and a live pick agree.
- `WallpaperService.current` is what the focused monitor shows: its
  workspace's own, else the one for every workspace (`allWorkspaces`, the saved
  config's path, else hyprpaper.conf's). The lock screen shows it; it used to
  be a hard-coded `whale.jpg` in `Style.lock`.
- **Add from file…** runs `services/wallpaper-import.sh`, which asks with
  zenity (Quickshell has no file dialog, and QtQuick.Dialogs would need a
  QApplication and QtQuick.Controls) and copies the image into the library:
  the same image again is a no-op, a different one under a taken name gets a
  `-1`, and a cancelled dialog exits 1 without an error. Verified with a
  stand-in zenity, not the real dialog.
- **PANELS Blur / Solid** is `Theme.blur`, which sets `Colors.base.opacity`
  for every shell surface at once: the bar, the dropdowns and popups, toasts,
  the OSD, the launcher and the app windows. Blur is the 50% frosted glass;
  Solid is opaque, for a wallpaper too light to read the bar over. A light
  theme's blur is 80%: at 50%, a light surface over a dark wallpaper went
  mid-grey and its dark text on it was unreadable. It is on the Appearance
  page.

**The wallpaper mode** is the row above the grid: **Static** keeps the pick,
**Rotate** moves on to the next wallpaper in the grid's order, wrapping, every
5 min / 15 min / 30 min / 1 h (the choices are `WallpaperService.rotateChoices`).
Each step sets the one for every workspace (a workspace's own stays), so the
saved config follows and a login
restores whichever wallpaper was showing. The mode and interval persist in
`Quickshell.statePath("wallpaper.json")`.

- **The service has to exist from login to rotate.** A singleton is built on
  first use, and nothing always on screen uses `WallpaperService`. The
  Settings app's scope, which `shell.qml` always builds, binds
  `WallpaperService.active`, and the timer runs only while `active`, rotating
  and the library holds more than one image.
- **A pick while rotating gets a whole turn.** Every successful apply restarts
  the timer, so a wallpaper chosen 17s into a turn stayed 60s (checked with a
  one-minute interval), not the 43s left of the old one.
- hyprpaper does not hoard what it was shown: three full cycles through the
  six wallpapers here took it from 106 MB to 141 MB, and the third added
  nothing.

**The workspace dropdown** (`WorkspacePanel`, the dropdown's left zone, which
the gesture and the bar's workspace dots open) ends with the same state: the
current wallpaper as a `WallpaperCard`, which closes the dropdown and opens
the Wallpaper page (the design's "Browse All Wallpapers →"), the Static/Rotate
choice in a compact `PillGroup` beside its title (with the interval while
rotating), and the theme's name with its six ANSI swatches, as its card on the
Themes tab draws them. The card is wider than the grid's 2:1
(`Style.workspaces.previewRatio`) so the workspaces keep the bulk of the
dropdown.

## The Settings app

`settings/SettingsApp.qml` is the Figma file's "Settings" frame, an ordinary
window (`FloatingWindow`, class `org.quickshell`, title "Settings") that
Hyprland tiles like any other, built by a `LazyLoader` only while open, so the
wallpaper thumbnails are freed when it closes. **SUPER+I** toggles it
(`settingsToggle`), SUPER+W opens it on the Wallpaper page, and so do `qs ipc
call settings toggle|open|close` and `openPage <name>`, the gear on the
quick-settings Toggles page and the workspace dropdown's wallpaper. Escape or
SUPER+C closes it. Whether it is open and on which page lives in
`services/SettingsState`, so anything can open it, as `DropdownState` does for
the dropdown.

The sidebar is the design's: the search field (filters by title and by a few
search words per page; Enter opens the first match) and its nine entries, plus
Keybinds and Startup, which the design does not have, after Power. Its
coloured dots are the design's placeholders for icons, so the entries carry
`nf-md` glyphs in `Colors.icon.active`, the bar's icon rule. Measurements are
the frame's at half its 2x size (`Style.settings`); text keeps the shell's
sizes.

- **Appearance** is the designed page. THEME is Light and Dark, and no Auto
  (the owner's call): `Theme` remembers the last light and the last dark theme
  applied, whatever applied them, by the palette's lightness once both of
  apply.sh's files have settled (`rememberDebounce`), and the pills apply those
  two; the checked one is the current palette's lightness. ACCENT COLOR is six
  of the palette's colours; the design's pink is cyan, since a terminal palette
  has no pink. FONT is a searchable `ChoiceField` of every installed family,
  each written in itself, the shell's own first. PANELS is Blur/Solid. The
  WALLPAPER card's "Change Wallpaper…" turns to the Wallpaper page.
- Bluetooth (below), Notifications (Do Not Disturb, then the centre itself, so
  toasts give way while it is shown), Power (the Battery page where there is a
  laptop battery, else just the power modes) and About (host, system, kernel,
  Hyprland and Quickshell versions, then the usage dropdown's details) are what
  the quick settings already have, in a `PanelCard` (the dropdowns' frame, the
  page's column wide, as tall as the panel asks and the window allows).
- Displays, Sound, Network, Keybinds, Startup and Wallpaper are pages of their
  own, each built on what it shows, below. A page is built while it is shown
  and no longer; one taller than the window is a `ScrollPage` (a `Flickable`
  with a thin bar at its right edge).

**Displays** reads `hyprctl monitors all -j` (again on Hyprland's monitor and
`configreloaded` events): an ARRANGEMENT map of the enabled monitors at their
logical size (scaled, turned for 90°/270°), then for the one clicked there
RESOLUTION (a `ChoiceField`, from `availableModes`), REFRESH RATE, SCALE,
ROTATION, ADAPTIVE SYNC and USE THIS DISPLAY (not offered for the last one on).
Changes wait in the page (`pending`, pruned back to nothing when set back) and
apply together with Apply. Dragging a monitor on the map lands it against the
side of the nearest other one it was dropped towards, edges within a tenth
snapping into line and the two always overlapping along the shared edge
(Hyprland finds monitors in a direction only across touching edges); a landing
that would cover a third monitor is refused, and the layout then shifts to
start at 0,0. SCALE offers only scales that leave whole logical pixels in 1/120
steps (fractional scaling's unit) and at least 960 wide; Hyprland would correct
any other.

Applying goes through `services/DisplayChange`, not the page: `displays.py
apply` hands the rules to `hyprctl eval` as `hl.monitor{…}` calls, and unless
Keep is pressed within 15 s the previous values are applied back — also with
the window closed, since a mode the screen cannot show leaves nothing to click.
Keep saves them (`displays.py save`) to `$XDG_STATE_HOME/quickshell/monitors.json`
and, as Lua, `monitors.lua` beside it, which `config/hypr/modules/monitors.lua`
applies after its own rules. Hyprland takes the newest rule matching a monitor,
at runtime (`hl.monitor` merges into a rule of the same name, else appends) and
at load alike, so kept rules win both times. Rules name a monitor
`desc:<make model serial>` where Hyprland has a description, so they follow it
to another port; ADAPTIVE SYNC is only written once touched, since an unset
`vrr` follows `misc:vrr`. "Reset to config" drops the kept rule and runs
`hyprctl reload`, the only way to lose a rule added at runtime.
`scripts/install-greeter.sh` appends the kept rules to the login screen's copy
of monitors.lua. NIGHT LIGHT has a warmth slider (2500–6500 K, kept in
quick-toggles.json); a running hyprsunset takes a new value through `hyprctl
hyprsunset temperature`, at most one call per 150 ms while dragging.

**Sound** is PipeWire's own lists (`Pipewire.nodes`, all bound with one
`PwObjectTracker`): OUTPUT and INPUT as radio lists, choosing with
`Pipewire.preferredDefaultAudioSink`/`Source`, each with the volume row of the
one in use (its icon mutes, the slider unmutes, as in the quick settings), and
APPLICATIONS, every stream playing sound with a volume of its own. A device is
named by its description, except where PipeWire ends it in `[nickname]`, the
monitor's name on HDMI, which is then the name; the right edge says what it is
(Bluetooth, HDMI, Digital (S/PDIF), USB, Built-in, Virtual). The filters go by
`PwNodeType` flags, and a playing app's stream is `AudioOutStream`, **Audio |
Sink | Stream**: `isSink` is true for it, since it plays into a sink.

**Network** is the Wi-Fi panel and, below it, what `nmcli device show` says
about each connected Wi-Fi or wired device (connection, IPv4, gateway, DNS,
IPv6, hardware address). It is read when the page opens and again after the
kernel reports an address or a route changing (`ip monitor address route`,
unprivileged), rather than every few seconds. `Quickshell.Networking` has no
IP addresses, hence nmcli.

**Bluetooth** is the quick settings' panel with pairing, in the dropdown and on
the page alike, and on the page a VISIBLE TO OTHER DEVICES switch
(`BluetoothAdapter.discoverable`), which pairing from the other side (a phone)
needs. The panel lists the paired devices, connected first with their battery,
then the ones found nearby with a name of their own (an unnamed one is only an
address). While it is shown and the adapter is on, it searches
(`discovering`); Pair pairs, then trusts the device (so it can reconnect by
itself) and connects it, as GNOME and KDE do; Cancel stops a pairing; Forget
unpairs on a second click within `Style.popup.confirmTimeout`; the header
switches the adapter on and off. Three things cost a round each, all found
against a stand-in BlueZ on a private bus (see the memory notes):

- **Search on the adapter's `state`, not `enabled`.** Quickshell sets
  `enabled` the moment it is written, so a search bound to it started before
  the radio was up, BlueZ answered `NotReady`, and switching Bluetooth back on
  left the page not searching.
- **A `Binding` destroyed with its page leaves its target as it is.** Closing
  the Settings page kept BlueZ searching for as long as the shell ran, and the
  Network page's Wi-Fi panel kept the scanner on. Both panels switch off what
  they switched on in `Component.onDestruction`.
- Pairing a device that wants a PIN or a passkey confirmed needs a BlueZ agent,
  which Quickshell 0.3 does not provide: here it is blueman-applet (its tray
  icon is hidden, the process stays for this). Devices that pair without one
  (headphones, speakers, most mice) need nothing.

**Keybinds** is `hyprctl binds -j`, read again on `configreloaded`. Hyprland
reports a Lua bind only as `__lua` and a callback number, so the names are the
`description` every bind in `config/hypr/modules/keybinds.lua` carries (the
wiki's way, `hl.bind(keys, action, { description = "…" })`). Binds with the
same description, modifiers and submap are one row, the keys side by side or a
run of digits as a range (SUPER + 1–9); an undescribed bind shows as "No
description". "Edit keybinds.lua" opens it with `xdg-open`, detached
(`Quickshell.execDetached`), since a `Process` child dies with its page.

**Startup** has two lists. STARTED BY HYPRLAND is `config/hypr/modules/startup.lua`,
a plain-data module (`{ name, command, about }`, conditions included, never
`hl`) that `modules/start.lua` runs on `hyprland.start`; the page reads it with
plain `lua` (`settings/startup-list.lua`; `lua` comes with Hyprland on Arch), so
it lists exactly what Hyprland runs, and it is edited there. Its Idle entry,
hypridle, reads `config/hypr/hypridle.conf` (there was none until 28 September,
so it exited at every login): `loginctl lock-session` after 5 minutes, which
hypridle answers with `qs ipc call lock lock`, and the screens off 30 s later. APPS is XDG
autostart, which uwsm hands to systemd-xdg-autostart-generator, so
`settings/autostart.py` decides what counts the way the generator does:
~/.config/autostart masks the system's by file name; Hidden, X-systemd-skip,
Type, Exec, TryExec, OnlyShowIn/NotShowIn (against XDG_CURRENT_DESKTOP) and a
GNOME phase count; X-GNOME-Autostart-enabled does not. Off is Hidden=true in a
copy of the system file; On removes that copy again when it differs in nothing
else, and keeps a user's own edits otherwise. Add app… copies an installed
app's .desktop in (found by its desktop entry id in the XDG data dirs); only an
entry the user's folder alone has can be removed. Each row says whether its
unit (`app-<id>@autostart.service`) is running. The generator runs at login,
and the page says changes take effect then.

**The accent** is `Colors.accent.primary`, what every accent in `Colors` now
is (calendar, Wi-Fi header, tray menu checks, the lock's busy ring). **The
font** is `Style.text.font`, which icons are drawn in too: fontconfig falls back
to a font with the Nerd Font glyphs, checked by rendering them under DejaVu
Sans, Noto Sans and two families that are not installed. Both reach the Qt apps
when themes apply to the apps; see THEMING.md.

## Themes

The palette `Colors` derives from (see Conventions) is chosen on the Wallpaper
page's Themes tab, which lists every wallust theme: the ones in
`config/wallust/colorschemes/` first, then wallust's 614 built-ins, each drawn
in its own colours. `config/wallust/palettes.py` builds that list by rendering
every theme through the shell's own template in a temporary config directory
(`-d`, with `-s` so no terminal is touched), so a card shows exactly what
applying gives; about 0.3s for all of them.

`style/Theme.qml` reads three files and writes none but its own:

| File | Holds | Written by |
| --- | --- | --- |
| `~/.cache/wallust/quickshell.json` | the palette | wallust, `templates/quickshell.json` |
| `$XDG_STATE_HOME/wallust/theme` | the theme applied, then `all` or `shell-only` | `apply.sh` |
| `$XDG_STATE_HOME/quickshell/appearance.json` | Blur/Solid, Shell/Shell and apps, accent, font, the last light and dark theme | `Theme` |

All three are watched, so `apply.sh Nord` from a terminal recolours the shell
live and the Themes tab shows Nord as applied. Picking a theme runs `apply.sh`,
with `--shell-only` when APPLY TO is "Shell"; a pick while one is running is
queued and only the latest survives (three back-to-back picks ended on the
third). "New from wallpaper" is `apply.sh --from <current wallpaper>`, which
saves a colorscheme into `colorschemes/`, in the repo, where it stays a theme
of its own. `.github/THEMING.md` has the wallust side.

**An ANSI slot is only trusted when it can be read.** Terminal themes keep
ANSI order, so `color1` is their red; a palette generated from a wallpaper
fills the slots by brightness instead (`mountains.jpg` gave `#111111` as its
"red"). So a slot stands in for its colour only when it is saturated (HSL
saturation ≥ 0.25) and has a WCAG contrast of at least 2 against the
background, and otherwise the shell's own colour does. Of wallust's 614
built-ins, this keeps all four of red, green, yellow and blue for 422, including every
popular one checked (Gruvbox-Dark, Nord, Oxocarbon-Dark, Catppuccin-Latte,
Dracula, Solarized-Light), and throws out a greyscale wallpaper's slots
entirely. A first version compared HSL lightness instead and rejected
Gruvbox's perfectly readable `#458588`, so the calendar's "today" went back to
the default blue.

Orange is not an ANSI colour: it is halfway between the red and yellow slots
when both are trusted, and the old `#d19a66` otherwise.

## Icons

Bar icons are monochrome, in `Colors.icon.active`, whatever their state; see
Conventions above. State is carried by the glyph: the Wi-Fi ramp, the battery
fill, the notification count, the ringed toggles dots.

**Every glyph is a Material Design one (`U+F0000`+).** The Font Awesome range of
the Nerd Font is not reliably covered by `Style.text.font` (`\uf028`, speaker,
rendered as an empty box in the bar for a long time), and the last Font
Awesome and weather glyphs (tray menu checks and chevrons, the calendar's
chevrons, the notification ×, the brightness ramp) were replaced on 27
September. `pango-view --font='JetBrainsMono Nerd Font 22'` renders candidates,
to check a new glyph actually draws before assuming the codepoint is wrong.

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
every icon in `Colors.icon.active` whatever its artwork, `0` leaves it alone.

Do **not** put `saturation` back alongside it. MultiEffect applies saturation
*after* colorization, so the previous `saturation: -1` stripped the tint out
again and colorization looked like it did nothing at all — including with
`colorizationColor` forced to pure red. That cost three round trips to diagnose.

Colorization neutralises hue but does not flatten luminance, so a dark
filled-disc icon still reads heavier than line art. Flattening that too would
need an alpha-as-mask `ShaderEffect` and a `qsb` build step.

The source `IconImage` is `visible: false`, which is the documented Qt pattern:
a `ShaderEffectSource` renders a hidden item. `Passive` items are no longer
dimmed: the tray sits in the bar's drawer now, and a half-transparent icon was
the same readability problem as the grey ones.

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
  persistence, body, body-markup, actions, icon-static, inline-reply.
  `sendInlineReply()` may only be called while `inlineReplySupported` is set.

Toast expiry and dismissal are deliberately different: a toast timing out calls
`expirePopup()`, which hides the toast but leaves the notification in the
centre; the `×` calls `dismiss()`, which destroys it everywhere. A `transient`
notification is the exception — the spec says it should skip any persistent
area, so it is expired rather than kept, and `NotificationService.list` filters
it out of the centre.

Critical notifications never auto-expire and keep their colour; right-clicking
the bar's bell toggles do-not-disturb, which suppresses toasts for everything
except critical.

**Inline reply** is KDE's: a notification with an `inline-reply` action gets a
reply field under its actions (`NotificationEntry`), in a toast and in the
centre alike, and Enter or the send button calls `sendInlineReply()`, which the
app receives as `NotificationReplied`. A toast does not expire while its field
has focus or text in it (`NotificationEntry.replying`).

The toast window's keyboard focus is `OnDemand` only while the pointer is on it
(a `HoverHandler` in its column) and `None` otherwise. Plain `OnDemand` looked
right and was wrong: Hyprland (`LayerSurface.cpp`, `onMap`) gives the keyboard
to a layer that maps with any focus but `None`, dropping the seat's focus grab
on the way, so every toast took the keyboard from the app in use and closed an
open dropdown — and so did the toast window following focus to another
monitor, since that maps it again. Switching an already mapped layer to
`OnDemand` takes nothing; Hyprland then focuses it on the next pointer motion
over it, which is the way into the field. Tested in the nested session: with
plain `OnDemand`, a line typed into a terminal after a toast appeared never
arrived; with the hover switch it did, and hovering a gdbus `Notify` with
`["inline-reply", "Reply"]`, clicking its field, typing and Enter produced
`NotificationReplied(6, "on my way")` and `NotificationClosed(6, 2)`, the
terminal got none of it, and focus returned to the terminal afterwards.

**Toasts move below an open popup** that lies across their column (the quick
settings, the power menu, the swipe dropdown's right zone) instead of over it:
`WidgetPopup` and `Dropdown` publish what they cover to `services/PopupAreas`
while open, and the toast window's top margin goes below the lowest of them on
its screen (both sit under the bar's exclusive zone, so the coordinates agree).
the owner chose this over holding toasts back or dropping them into the centre (27
September). In a nested session a toast sat at y 305 under the open quick
settings instead of 57, and went back up once they closed; the popup stayed
open throughout, hovered toast included.

**A toast that follows focus to another monitor fades in** there
(`Style.animation.slow`) instead of appearing at once; `onScreenChanged` on the
toast window restarts it.

**The centre opens in the toasts' column, not under the bell.** It used to be
a `Style.dropdown.width` popup centred on the bell, and the bell moves with the
bar's drawer: open, the centre floated mid-screen; closed, it was clamped to the
right edge but 20px narrower than the toasts. It now leaves `anchorItem` unset
and takes `Style.notifications.width`, so it covers exactly the column a toast
occupies (both measured at x 1085–1424 on the laptop). That makes the two
overlap exactly, so toasts give way to it: `NotificationPanel` counts itself in
`NotificationService.viewers`, opening a centre expires the toasts showing, and
nothing raises a toast while one is open, since the centre lists it as it
arrives. A transient notification is expired at once instead, because the
centre does not list it and it would otherwise stay tracked forever.

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

## Workspaces per monitor

Every monitor numbers its own workspaces from 1, and none exist in advance.
The keys act on the focused monitor, which follows the pointer
(`misc.mouse_move_focuses_monitor`, on by default):

| Keys | Does |
|---|---|
| SUPER+1–9, SUPER+SHIFT+1–9 | go to / take the window to that number on the focused monitor |
| SUPER+←/→ | the previous / next workspace on it, as the three-finger swipe goes: through the ones there are, past the last to a new one unless the last is empty |
| SUPER+CTRL+arrows | focus the monitor in that direction |
| SUPER+CTRL+SHIFT+arrows | take the window there (SUPER+SHIFT+number cannot cross monitors any more) |
| SUPER+↑/↓ | move focus between windows, as before |

Hyprland's workspace ids are global, so `config/hypr/modules/workspaces.lua`
gives each monitor a block of 100 — 1–99, 101–199, … — and a workspace's
number is `id % 100`. The dropdown's `WorkspacePanel` shows that number.

- **Blocks go by output name, for the session**, kept in
  `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/workspace-blocks.json`,
  which the shell reads too (`services/WorkspaceBlocks`: the panel's numbers,
  the wallpaper's workspace keys). Not Hyprland's monitor ids: with no monitor left,
  the FALLBACK output takes one (nested: it took the id of the output removed
  last), and it is only destroyed after the first real monitor is back, so that
  monitor gets another id (`getNextAvailableMonitorID`). Not a Lua table either:
  `reload()` recreates the Lua state (`reinitLuaState`), globals included.
- **A monitor's first workspace**: Hyprland creates it with the lowest free id
  (`findAvailableDefaultWS`), in someone else's block for every monitor but the
  first. `settle()` then shows the monitor's own first workspace if it has any
  (one coming back from unplugged), and otherwise focuses the monitor, opens
  its workspace 1 there, and puts focus and pointer back, all in the one
  handler. It does not renumber with `hl.dsp.workspace.change_id`, which works
  in Hyprland: Quickshell 0.3.1 ignores the `changeworkspaceid` event, and
  `Hyprland.refreshWorkspaces()` from QML neither adds nor removes an entry
  (`canCreate = false`), so the old id stayed in the bar. Workspace rules could
  not do it up front: they bind exact ids only (`getBoundMonitorStringForWS`).
- **On a config reload** the monitors already there are settled too, the ones
  showing windows first, so a first reload of this config keeps the numbers of
  whatever is on screen.
- **An unplugged monitor's workspaces** wait on another monitor (Hyprland moves
  them and moves them back by name, `m_lastMonitor`). They are reachable there
  with SUPER+←/→, and the panel lists them after the monitor's own, marked with
  U+F0D90 (a crossed-out monitor). SUPER+→ does not open new ones past them.
- **SUPER+CTRL+arrows need touching edges**: `directionLookup` only takes a
  monitor whose edge sticks to the focused one's. `monitors.lua` places
  HDMI-A-1 `auto-right`, i.e. after whichever monitors have a fixed position
  (Hyprland arranges those first): 1920 beside the desktop's DP-2, 1440 beside
  the laptop's eDP-1 at scale 2, where a fixed x=1920 used to leave a gap.
  Checked nested: a scale-2 output at 0x0 and one `auto-right` touched at
  x=960.
- The panel header draws the monitor layout (this one filled in) and names the
  output, only while more than one screen is connected
  (`Style.workspaces.mapHeight`, `mapGap`, `mapRadius`).
- Tested in a nested Hyprland with real key presses from a
  `zwp_virtual_keyboard_v1` client (Hyprland runs virtual keyboards through its
  keybinds unless they belong to the input method) and a virtual pointer to
  choose the monitor: every key above, a second output coming up, unplug and
  replug, a first reload without the file, and the panel's tiles through a
  test-only IPC probe. Not testable there: every output gone at once — the
  nested backend creates no output after that.

## Things that have already cost a bug

**A click outside a `HyprlandFocusGrab` only ends the grab.** Hyprland sends the
press to the grabbed surface and just the release to what is under the pointer,
so no `MouseArea` there fires: clicking the clock while the workspace zone is
open closes the dropdown, and a second click opens the calendar. The same holds
between any two popups, so nothing on the bar can re-target an open dropdown.
Measured in a nested Hyprland with a virtual pointer, after a first version had
the dropdown close and reopen on every `open()` to renew its grab — for a click
that never arrives.

**`Hyprland.dispatch()` takes Lua here.** Under the Lua config the request
becomes `return hl.dispatch(<argument>)`, so the power menu's Logout, which sent
`exit`, got `hl.dispatch: expected a dispatcher` back and did nothing. It sends
`hl.dsp.exit()` now, like the greeter. `HyprlandWorkspace.activate()` is fine:
Quickshell 0.3.1 checks `Hyprland.usingLua` and sends
`hl.dsp.focus({ workspace = "<name>" })` itself.

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
Typed *parameters* without one make it `void`, and the engine logs an error per
call site — 42 of them for a month grid; `CalendarPanel.dotColours()` logged 70
every time the calendar opened until 27 September, after Qt 5's qmlformat had
cut its `: list<color>` down to `: list`. A function with no annotation at all
is plain JavaScript and logs nothing, which is why `dotColours(day)`,
`modifierNames(mask)`, `DisplaysPage.rule()` and `landing()` have none.

**`state` is taken.** Every `Item` has a `state` (its `States`), so a page's own
`property var state` clashes; the Displays page calls it `selectedState`.

**A `Binding` destroyed with its object leaves its target as it is.** It only
restores when `when` turns false. A Settings page is destroyed when you leave
it, so a Binding that switched something on (BlueZ's search, the Wi-Fi
scanner) must switch it off in `Component.onDestruction`; see Bluetooth under
The Settings app.

**A `qmldir` line goes in before its first user.** A file that uses a new
component before the `qmldir` names it fails the reload ("X is not a type"),
and saving only the `qmldir` afterwards does not reload anything: the shell
stays on the last good generation until some `.qml` changes, or restarts.
Copying into the live tree: new files, then `qmldir`s, then the files using
them.

**Several Hyprland modules saved at once race the autoreload.** Hyprland
watches every file the config loaded and reloads on the first write; the
reload resets the watches and re-reads the tree, so modules written a moment
later can be missed, and the running config is a mix until the next save.
After copying several, run `hyprctl reload`.

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
at a time. Mapping is the exception that bites the other way: Hyprland hands
the keyboard to a layer that *maps* with any focus but `None`, and drops the
current grab doing so. For a surface that appears unasked that is a focus
steal; see the toasts under Notifications.

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
- `request()` clamps to `Brightness.minimum` (5%) before it moves `level`, so the
  slider cannot black the screen and never shows a value below the floor.
  swayosd's `min_brightness` did this before swayosd went.

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
panel. The toast window is the one deliberate exception, switching between
`None` and `OnDemand` with the pointer: it has no grab of its own, and that
switch leaves other grabs alone (a toast hovered while lying over an open
dropdown did not close it).

**A `Process` child can outlive the shell.** Quickshell's docs say children are
killed when quickshell dies, but a SIGTERM'd `qs` left its child running,
reparented to `systemd --user`. A reload is fine, because the old generation's
`Process` is destroyed and takes its child with it. Anything long-lived that
must not survive the shell itself goes through `setpriv --pdeathsig TERM`; see
Quick toggles for what an orphaned hyprsunset did.

**Units that aren't what they look like.** `UPowerDevice.percentage`,
`WifiNetwork.signalStrength` and `PwNodeAudio.volume` are all **0.0–1.0 ratios**,
not 0–100.

**A nested Wayland output has no modes.** `availableModes` is empty there, so
a rule with `mode = "preferred"` cannot be applied at runtime (aquamarine:
"pending state rejected: invalid mode") and the output keeps its last state; a
reload looked like it did not reset a scale. Rules tested nested need an
explicit mode (`1920x1080@60`); real outputs resolve `preferred` fine.

**Private-use glyphs get lost in transit.** The calendar's month chevrons were
silently emptied to `""` at some point by a tool that dropped the codepoints,
and this very note held a pasted glyph where it meant an escape. Every glyph is
written as an escape, `"\u{F0141}"`, and `scripts/pasted-glyphs.py` (in
`check.sh`) fails on a pasted one.

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
rule that every Nerd Font glyph is an escape, python/lua/shell parsing, the
two Hyprland configs through Hyprland's own parser (it rejects unknown rule
fields, which `luac -p` cannot), and `tests/`. The pre-commit hook formats
staged QML and re-stages it; pre-push runs the suite without modifying
anything.

**qmllint allows no warnings**, unused imports included, and checks every
member read on the design tokens and on Quickshell's types: `Style.bar.heigth`
fails with "did you mean height", as does `adapter.discovring`. It did not
until 28 September, when 1384 warnings hid the few that mattered. Three things
made them go:

- **Quickshell's type information is fixed before linting.** Its qmltypes name
  types without their C++ namespace, its submodules leave out `depends
  Quickshell`, and more (the list is in `scripts/quickshell-types.py`, which
  writes the corrected copy check.sh lints against). Its QML is untouched.
- **`Style` and `Colors` groups are inline component types** (`component
  BarStyle: QtObject {…}`, then `readonly property BarStyle bar: BarStyle {}`)
  rather than bare `QtObject`s, whose members qmllint cannot see. A group
  reaches another through the root id (`root.palette.foreground`), which needs
  `pragma ComponentBehavior: Bound` in the file.
- **`pragma ComponentBehavior: Bound`** in every file whose delegates read an
  outer id, and delegates take their model data as `required property`, never
  the implicit `modelData`. What a `Loader` holds is read typed: its
  `implicitHeight`, or a cast (`(content.item as QuickSettingsPanel)?.step(…)`).

Writes inside a handler (`adapter.discovring = false;`) and anything reached
through a `var` stay unchecked, so the shell's log is still the last word. By
hand, with the corrected type information:

```bash
scripts/quickshell-types.py /tmp/qs-types
/usr/lib/qt6/bin/qmllint --bare -I /tmp/qs-types -I /usr/lib/qt6/qml --max-warnings 0 $(find .config/quickshell -name '*.qml')
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

## Installing

Setting a clone up is Jupiter-installer's job; README "Installing" lists the
steps. What these dotfiles need beyond `base` is its `packages/core.txt`
(phase 2) and `packages/aur.txt` (phase 3), so a new dependency goes there.
Its phase 4 links every non-hidden entry of `.config/` into `~/.config/` (and
`.config/.zshrc` to `~/.zshrc`), so a new config folder needs nothing added to
the installer, and it removes links into a folder the repo no longer has. It
also runs `scripts/install-greeter.sh`, which stays here because it is run
again whenever the greeter's inputs change.

A first login was checked on 28 September: the setup script this repo had then
(the installer's phase 4 now) into an empty home from a
copy of the working tree with its git-ignored files removed (a fresh clone),
then that copy's own `hyprland.lua` in a nested Hyprland, hypridle and the
keyring left out of its start list and `apply.sh` given `-s`. No config errors,
the shell up with nothing in its log, the Oxocarbon-Dark files rendered by the
start list's `apply.sh`, the Wallpaper page's empty state. Hyprland's own
background shows until a wallpaper is picked, and every wallpaper preview logs
"Cannot open …/whale.jpg" until then: `hyprpaper.conf` names that file, which
only exists where `~/Wallpapers` is synced.

## Entry points, for testing by hand

```bash
qs ipc call launcher toggle
qs ipc call dropdown openAt 904 740    # zone from a pointer position
qs ipc call dropdown open calendar     # a zone by name
qs ipc call dropdown open quicksettings
qs ipc call lock lock                  # no unlock IPC exists, by design
qs ipc call lock locked
qs ipc call settings toggle            # also open, close, openPage appearance
qs ipc call settings openPage keybinds # displays, sound, network, wallpaper, …
~/.config/wallust/apply.sh Nord        # the shell follows; see Themes
```

`SUPER+R` (launcher), `SUPER+L` (lock), `SUPER+B` (bar drawer), `SUPER+W`
(Settings on the Wallpaper page) and `SUPER+I` (Settings) are `GlobalShortcut`s bound with
`hl.dsp.global(...)`; the three-finger swipe is an
`hl.gesture` block calling `dropdown openAt`. All in
`config/hypr/modules/keybinds.lua`. Any of them can be fired without the key,
e.g. `hyprctl dispatch 'hl.dsp.global("quickshell:barExpand")'`. In
`hyprctl binds` a Lua bind shows as dispatcher `__lua` with a callback number,
not the global's name; every bind there carries a `description` for that
reason, which is what the Settings app's Keybinds page names it by.

Hyprland here is configured in **Lua**, so `hyprctl dispatch` takes a Lua
expression — `hyprctl dispatch 'hl.dsp.focus({ monitor = "eDP-1" })'`, not
`hyprctl dispatch focusmonitor eDP-1`. The hyprlang spelling fails with exit 7
and does nothing; `/usr/share/hypr/stubs/hl.meta.lua` lists the dispatchers.

## Runtime facts that affect the code

- **NetworkManager** is the only backend `Quickshell.Networking` supports.
- The lock authenticates against pam.d **`login`** (`LockService.pamConfig`);
  `pam_unix` goes through setuid `unix_chkpwd`, so quickshell needs no
  privileges. A config reload while locked used to drop the lock — `locked`
  lives in `PersistentProperties` now.
- `misc:allow_session_lock_restore` is on in `config/hypr/modules/session.lua`,
  so a restarted shell can retake an orphaned lock (TTY → `qs` → unlock).
- Brightness **writes** go through `brightnessctl`, as the brightness keys do
  now that they reach the shell's OSD; reads come from `/sys/class/backlight`,
  and the widget hides itself when that directory is empty. The desktop has no
  backlight, and no `brightnessctl` installed either, so none of this runs
  there.
- Night Light needs `setpriv` (util-linux) as well as `hyprsunset`; see Quick
  toggles.
- **wallust is not on the shell's `PATH`** on the desktop, where it is a cargo
  install in `~/.cargo/bin` (a fresh install gets the AUR package, in
  `/usr/bin`). Only `.zshrc` adds that folder, and nothing the compositor starts
  (the shell included) reads `.zshrc`. `apply.sh` prepends it and `palettes.py`
  looks there too. Until that fix the login-time `apply.sh` failed with
  `command not found`, silently: on 24 September every generated colour file
  still dated from a terminal run on the 13th, not from that day's login.
- "Add from file…" needs `zenity`; hyprpaper is 0.8.4, whose config and IPC
  quirks are in "Wallpaper & Background".
- The Clipboard tile needs `cliphist` (and `wl-clipboard`, installed), Screen
  Record `wf-recorder` and `xdg-user-dir`; both run under `setpriv`.
- The Settings app's Startup page runs `lua` (the `lua` package, which Hyprland
  depends on) and `python3`, as do Displays (`python3`, `hyprctl`) and Network
  (`nmcli`, NetworkManager's). Kept monitor rules are
  `$XDG_STATE_HOME/quickshell/monitors.{json,lua}`; nothing is kept until a
  change is kept there.
- A DBus-activated notification daemon will silently hold
  `org.freedesktop.Notifications` unless masked, and a shell-owned notification
  server cannot coexist with it. Masked here: `dunst`. `swaync` is not installed
  on this machine.
