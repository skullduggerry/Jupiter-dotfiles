# Quickshell config

A [Quickshell](https://quickshell.org/) desktop shell for Hyprland: a top bar
(workspaces, clock, tray, volume, Wi-Fi, Bluetooth, battery, power), an app
launcher, and a three-zone dropdown (workspace overview, calendar, Wi-Fi)
opened by a three-finger swipe — all built as widget-styled QML.

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
- `python3` (standard library only) for `services/nextcloud-calendar.py`,
  the CalDAV helper behind the calendar dropdown. Optional:
  `secret-tool` (libsecret) if you'd rather keep the Nextcloud app password
  in the session keyring than in an environment variable
- Hyprland **0.49+** for the swipe dropdown, whose gesture actions can be Lua
  callbacks. No gesture daemon (`libinput-gestures`, `fusuma`) is needed

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

## Swipe dropdown

A three-finger swipe down opens one dropdown, with the content chosen by the
third of the monitor the pointer sits in: **left** the workspace overview,
**middle** the calendar, **right** the Wi-Fi list. Swiping over the same zone
again closes it; swiping over a different one swaps the content.

The compositor side is a `hl.gesture` block in
`../hypr/modules/keybinds.lua`, which reads the pointer position and hands it
to the shell:

```lua
hl.gesture({
    fingers = 3,
    direction = "down",
    action = {
        finish = function()
            local pos = hl.get_cursor_pos()
            hl.exec_cmd(string.format("qs ipc call dropdown openAt %d %d",
                math.floor(pos.x), math.floor(pos.y)))
        end,
    },
})
```

The zone decision itself lives in the shell (`services/DropdownState.qml`),
measured against the monitor the pointer is on, so the same gesture behaves
the same on every screen. The same entry points work by hand:

```sh
qs ipc call dropdown openAt 904 740   # zone from a pointer position
qs ipc call dropdown open calendar    # a zone by name
qs ipc call dropdown close
```

Clicking the bar's clock opens the calendar zone directly.

## Nextcloud calendar

The calendar dropdown gets its events from
`services/nextcloud-calendar.py`, a standard-library CalDAV client that
`services/CalendarService.qml` runs through `Process`. Credentials never
touch QML. Configure it with two environment variables and a keyring entry:

```sh
# in ~/.zshrc, or any environment quickshell inherits
export NEXTCLOUD_URL=https://cloud.example.org
export NEXTCLOUD_USER=your-login
```

```sh
# the password, kept out of your shell profile and out of `ps`
secret-tool store --label='Nextcloud' service nextcloud username your-login
```

Use a Nextcloud **app password** (Settings → Security → Devices & sessions),
not your account password: it can be revoked on its own and bypasses 2FA.
`NEXTCLOUD_APP_PASSWORD` is honoured too if you'd rather not use a keyring.

Recurring events are expanded server-side (RFC 4791 `<C:expand/>`), so the
helper never interprets an `RRULE`. Test it on its own — it prints one JSON
object either way:

```sh
services/nextcloud-calendar.py --start 2026-09-01 --end 2026-10-01
```

Until it's configured, the calendar panel says so instead of looking broken,
and `CalendarService` makes no requests at all while every calendar surface
is closed.

## Validating changes

```sh
qmllint -I /usr/lib/qt6/qml $(find . -name '*.qml' ! -name 'Launcher.qml' ! -name 'Dropdown.qml')
```

`launcher/Launcher.qml` and `dropdown/Dropdown.qml` are excluded because
qmllint 1.0 crashes (exit 255, no output) on `void` and `var` in a function
signature, and Quickshell's `IpcHandler` requires annotated functions —
`function f(): void`. That's a linter bug, not a problem with those files.
Concrete types (`bool`, `date`, `int`, `string`, `real`, and QML types like
`ShellScreen`) are fine, so anything whose value is used in a binding can and
should be annotated:

> Any function whose return value is read from a property binding **needs a
> return type**. Without one the QML engine treats the return as `void` and
> logs an error per call site — 42 of them, for a month grid. That rules out
> returning a JS array from a function, since `var` crashes the linter; put
> the array in a `property var` binding instead (see `CalendarService`'s
> `eventsByDay`).

Quickshell watches these files and hot-reloads on save, so the fastest check is
usually to just save and read the log:

```sh
qs log -r '*.debug=true;*.info=true' -- /run/user/1000/quickshell/by-id/<id>/log.qslog
```

Be aware that a wrong Quickshell API can fail *silently* — see the
`ObjectModel` note in `PROJECT_STRUCTURE.md` and Phase 2.5 in `TODO.md`.
