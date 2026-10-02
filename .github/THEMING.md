# Theming — agent reference

How colour gets to every app in this repo. `.github/PROJECT_STRUCTURE.md`
covers the quickshell shell itself.

## The chain

```
Settings → Appearance → Themes, or apply.sh by hand
        │
        ▼  config/wallust/apply.sh [--shell-only] THEME | --from IMAGE
   wallust theme THEME          a built-in
   wallust cs THEME.json        one of colorschemes/, the repo's own
        │
        ├─ templates/quickshell.json  → ~/.cache/wallust/quickshell.json          (the shell's palette)
        ├─ templates/kitty.conf       → ~/.config/kitty/colors.conf              (gitignored)
        ├─ templates/nvim.lua         → ~/.config/nvim/lua/colors.lua            (gitignored)
        ├─ templates/kdeglobals       → ~/.cache/wallust/kdeglobals              (merged, see below)
        │                             → ~/.local/share/color-schemes/Wallust.colors (KDE apps' colours)
        ├─ templates/qt6ct.conf       → ~/.config/qt6ct/qt6ct.conf                (Qt's style, icons, font)
        ├─ templates/Wallust.kvconfig → ~/.config/Kvantum/Wallust/Wallust.kvconfig (gitignored)
        ├─ templates/Wallust.svg      → ~/.config/Kvantum/Wallust/Wallust.svg      (gitignored)
        ├─ templates/gtk-3.0.css      → ~/.local/share/themes/Wallust/gtk-3.0/gtk.css (GTK 3 apps)
        ├─ templates/gtk-4.0.css      → ~/.local/share/themes/Wallust/gtk-4.0/gtk.css
        ├─ templates/gtk.css          → ~/.config/gtk-4.0/gtk.css                 (GTK 4 apps' colours)
        └─ templates/color-scheme     → ~/.cache/wallust/color-scheme            (prefer-dark / prefer-light)
        │
        ├─ kdeglobals.py merges ~/.cache/wallust/kdeglobals into ~/.config/kdeglobals
        ├─ gsettings org.gnome.desktop.interface color-scheme ← color-scheme
        └─ gtk-theme.sh names the Wallust GTK theme (gsettings gtk-theme), see "GTK apps"

   then $XDG_STATE_HOME/wallust/theme: the theme's name, then "all" or "shell-only"
```

**The Settings app's accent and font reach the app templates too.** wallust
cannot be handed variables, so `apply.sh` renders from a temporary folder of
symlinks to `templates/`, `colorschemes/` and `wallust.toml` (`-d`), in which
`templates/appearance.jinja` is replaced by what `appearance.py` writes from
the shell's `appearance.json`: `accent_color()` (the palette slot of the
chosen accent) and `font_family()`, and from the tint the shell recorded
beside it (`tint.conf`) `window_opacity()`, the Qt apps' glass (below). As
committed, that file holds the defaults, so the templates render on their own
too (the tests, `palettes.py`).
The shell passes its current choice as `APPEARANCE_ACCENT` and
`APPEARANCE_FONT` as well, which win over the file: the first version read the
file only and rendered the previous accent, because `Theme` debounces its
writes. The accent colours the apps' selection, focus and active text
(kdeglobals, Kvantum's highlight and the SVG's accented fills); links stay the
palette's blue. The font becomes qt6ct's `general` font; `fixed` stays
JetBrainsMono.

`templates/palette.jinja` is not a template of its own: it holds the colour
arithmetic the others import (`{% from "palette.jinja" import shade %}`), the
same formulas as `style/Colors.qml` — `mix(a, b, t)`, `shade(t)` for t of the
way from the background to the text, `accent(t)`, `selection(t)`, and
`scheme()` for "dark" or "light" by HSL lightness, as Colors judges it. Every
surface an app template draws is a `shade()`, which is what makes a light theme
mirror a dark one instead of drawing dark greys under dark text.

`--shell-only` renders through `shell.toml`, which lists the quickshell
template alone, and passes `-s` so the open terminals keep their colours: the
shell changes and the apps stay as they were. It is what the app's
"APPLY TO: Shell" means.

**Bare, `apply.sh` applies the recorded theme again, the same way.** That is
what `modules/start.lua` runs at login, so a login never undoes a choice, and
it is also what renders every colour file on a fresh clone (Oxocarbon-Dark,
the default, before anything was recorded). `WALLUST_THEME=X apply.sh` is the
same as `apply.sh X`.

**Oxocarbon-Dark stays the default rather than a palette from the
wallpaper.** Running `wallust run ~/Wallpapers/whale.jpg` replaces the whole
palette with a washed-out monochrome blue, which is why the fixed theme was
chosen. A palette from the wallpaper is now an explicit choice instead: "New
from wallpaper" is `apply.sh --from <image>`, which saves it as
`colorschemes/<image name>.json` in the repo, a theme like any other. The
shell ignores any of its ANSI slots too grey to read; see "Themes" in
PROJECT_STRUCTURE.md.

`wallust.toml` is templates only. It used to carry `backend = "wal"` and
`palette = "dark16"`, which only affect image-derived runs: rendering all four
templates with and without them gave byte-identical output. `--from` runs
wallust's defaults (the `fastresize` backend). Every template uses `target=`,
the key wallust's v3 spec names; `dst=` is an alias of it.

`wallust theme <name> --preview` shows a palette without writing anything —
but only without `-q`: 3.5.1's `main.rs` returns early for a preview only when
not quiet, so with `-q` the theme is applied for real (read in the source, not
tried).

**Test with `-s`.** Without it wallust writes the palette as escape sequences
to every `/dev/pts/*`, i.e. into every terminal the user has open, and a
template render error is only a warning: wallust still exits 0.

### What changes live

| Target | When a theme is applied |
| --- | --- |
| The shell | at once: `style/Theme.qml` watches the palette file |
| Open terminals, kitty's included | at once, from the escape sequences (not with `--shell-only`) |
| New kitty, Qt windows | at start, from the files above |
| kitty's background opacity | at once, from the shell's glass tint, over each kitty's socket (not with "Shell"); see PROJECT_STRUCTURE.md, Wallpaper & Background |
| Qt apps' window glass | at their next start, from Kvantum's SVG, which the shell rewrites when the tint changes (not with "Shell"); a running one cannot take it, below |
| Running Qt apps, Dolphin included | colours and style at their next start, icons and font at once: see below |
| The blur behind any window | at once: it is Hyprland's |
| GTK 3 apps, the file dialogs included | colours and glass at once: the theme is named anew (see "GTK apps") |
| GTK 4 apps | colours and glass at their next start, dark or light at once |
| Electron, browsers; Qt apps on an "automatic" theme of their own | dark or light at once, through the portal's `color-scheme` |
| A running nvim | at once: `init.lua` watches `lua/colors.lua` and runs it again |

**Running Qt apps keep their colours until they restart.** Outside Plasma
nothing makes them reread a theme: a KDE app loads its colour scheme once, at
start (`KColorSchemeManager::init`, kcolorscheme 6.30), and Kvantum reads its
theme when the style is created. qt6ct watches `~/.config/qt6ct/` and gives
open windows a changed icon theme and font (qt6ct 0.11, `createFSWatcher`), so
after a switch between dark and light an open Dolphin shows the new icons on
the old colours until it is restarted. Restyling in place was
plasma-integration's platform theme, which comes with Plasma itself (see
"Packages").

**Nor does a running Qt app take a new glass, and cannot.** Kvantum makes a
window translucent when it first polishes it, and paints the background only
of windows it made so. The one way left to make a running app read the SVG
again is to rebuild the style in place: qt6ct's proxy style does, when the
style it names changes (`kvantum` and `kvantum-dark` are both Kvantum here;
`[KDE] widgetStyle=qt6ct-style` puts KDE apps on that proxy too). Tried on
2 October against a Dolphin on a scratch config: the rebuilt Kvantum took the
windows for ones the app had made translucent itself and painted no
background, so the views went from alpha 107 (the 0.42 tint) to 0, the window
see-through but for the toolbar and the text. Touching qt6ct's folder without
changing the name rebuilds nothing (`Qt6CTProxyStyle::reloadSettings()`
compares it). So kitty and GTK 3 apps follow the tint at once and Qt apps at
their next start, as the line under the TINT slider says; a Dolphin that
D-Bus started for `org.freedesktop.FileManager1` (`dolphin --daemon`, for a
browser's "show in folder") keeps the glass it started with while it runs.
The blur does reach open windows at once: Hyprland's `decoration:blur:size`
changed Dolphin's frames as it changed (checked at 1, 8 and 12), if subtly
over a soft wallpaper.

**nvim** runs `lua/colors.lua` from `init.lua`, which was commented out until
the template mapped the palette properly: it used to put the terminal's slots
straight into base16's (`base01`, the status line, was the theme's red). base16
slots are roles, 00 to 07 from the background to the text, so those are
`shade()`s now and 08 to 0F the accents. `init.lua` watches the file's folder
with `vim.uv.new_fs_event()` and reruns it when wallust writes it, then puts
`Normal`'s background back to none so the terminal's translucency shows.
Verified with a headless nvim across a Latte ↔ Oxocarbon switch.

### Template filters

Wallust 3.5.1. Confirmed present: `strip` (hex without `#`), `rgb` (`29,31,33` —
what kdeglobals wants), `red`/`green`/`blue`, `lighten(f)`, `darken(f)`,
`saturate(f)`, `complementary`, `blend(c)` (50/50 only; a second argument is an
error). **Not** present: `rgba`, `xrgba`, `alpha`, `desaturate`, `invert`,
`grey`, `mix`. `hexa` prints nonsense (`#51177255FF` for `#33B1FF`).

The engine is minijinja, with its own builtins, which is where the arithmetic
comes from: macros, `{% from "palette.jinja" import … %}` (resolved in
`templates/`, and an imported macro sees the palette variables), `set`,
inline `if`/`else`, `[…] | max`, and `"%02x" | format(n)`. `red` and friends
return strings, so `| int` before any sum. A template that fails to render is a
warning and an untouched target, never an exit status; `tests/wallust-templates-test.py`
renders every template for a dark and a light theme and fails on any warning.

To try a template without touching the live colours, render it in an isolated
config dir:

```bash
wallust -d /tmp/wtest -q -s cs <scheme> -f pywal
```

`-d` points at a whole config dir (its own `wallust.toml`, `templates/`,
`colorschemes/`), `-q -s` keep it quiet and stop it writing terminal sequences.
A pywal-format colorscheme built from the current `colors.conf` round-trips
losslessly, so it is a faithful stand-in for the live palette.

## Qt / KDE apps (Dolphin)

Five pieces, each owning something different. Getting any one wrong looks like
"the theme just doesn't apply".

| Piece | Owns | Where |
| --- | --- | --- |
| `QT_QPA_PLATFORMTHEME=qt6ct` | every Qt app's widget style, icon theme and font | `config/uwsm/env`, `templates/qt6ct.conf` |
| The Wallust colour scheme | KDE apps' colours | `templates/kdeglobals`, rendered to `color-schemes/Wallust.colors` |
| kdeglobals | which colour scheme, style and icon theme KDE apps load | `templates/kdeglobals`, merged by `kdeglobals.py` |
| Kvantum theme | how widgets are drawn, window translucency, other Qt apps' colours | `templates/Wallust.kvconfig` + `templates/Wallust.svg` |
| Hyprland `decoration:blur` | the blur behind it | `styles/layout.lua`, its size from the Settings app's `blur.lua` when kept |

**The Qt variables live in `config/uwsm/env`**, symlinked to
`~/.config/uwsm/env` like the other config folders. uwsm starts Hyprland here
(the greeter prefers its session), sources that file first and exports it to
systemd as well; Hyprland's wiki asks uwsm users to keep toolkit and theming
variables there rather than in the Hyprland config. As `hl.env` in
`modules/env.lua` they only reached what Hyprland started: Nextcloud, started
by xdg autostart through systemd, had `QT_QPA_PLATFORMTHEME` only because
Hyprland exports that one variable itself, and no
`QT_WAYLAND_DISABLE_WINDOWDECORATION`. `modules/env.lua` reads the same file
when uwsm is not in use (`UWSM_FINALIZE_VARNAMES` unset). After the first
login with it (27 September) both variables were in `systemctl --user
show-environment`, in Hyprland's own environment (set once, by uwsm) and in
Nextcloud's and kdeconnectd's.

Three things cost real time here, all established by experiment:

> **Outside Plasma, KDE apps ignore the colours in `~/.config/kdeglobals`.**
> Dolphin launched with no platform theme, and again with `-style breeze`,
> stayed fully light Breeze with a complete dark `[Colors:*]` in kdeglobals, and
> `[Colors:View] ForegroundNormal` set to pure red changed nothing either. Only
> plasma-integration's platform theme applies those. Anywhere else a KDE app
> loads the colour scheme that `[UiSettings] ColorScheme` names from
> `color-schemes/`, and with none named, Breeze Light or Breeze Dark by the
> system's preference (`KColorSchemeManager::init`, kcolorscheme 6.30): the
> light Breeze seen here.

> **qt6ct tripped over the same thing.** Under it KDE widgets (Dolphin's Places
> panel, the file view, the breadcrumb) were unreadable dark grey on dark:
> Kvantum's dark theme over Breeze Light's palette, as no scheme was named. With
> `ColorScheme=Wallust`, a probe program against KF 6.30 and Qt 6.11 read the
> same palette, colour scheme, style, icon theme and font under qt6ct as under
> plasma-integration, for Oxocarbon-Dark and Catppuccin-Latte.

> **`widgetStyle` lives in the `[KDE]` group, not `[General]`.** With it in the
> wrong group the colours were correct but the window was opaque, because
> Kvantum was never selected and Breeze was painting.

**kdeglobals is merged, not rendered over.** KDE apps write settings of their
own there (the file dialog's view, for one), and `apply.sh` runs at every
login, so rendering the whole file threw them away every time. wallust renders
to `~/.cache/wallust/kdeglobals`, and `kdeglobals.py` replaces only the keys
the template sets, drops comments as KConfig does, and writes beside the file
and renames over it.

**The icon theme follows the background**: `breeze` for a light theme,
`breeze-dark` for a dark one (`scheme()`), in kdeglobals for KDE apps and in
`qt6ct.conf` for the rest. breeze-dark's white glyphs were unreadable on a
light palette.

**Translucency**: Kvantum's `[%General] translucent_windows=true` +
`composite=true`, which makes only the window *background* translucent — text
and icons stay opaque, the same deal as kitty's `background_opacity`. Do
**not** use `reduce_window_opacity`: that fades the whole window, text
included. Hyprland blurs any translucent window already, so no window rule is
needed.

**How translucent is the SVG's business, and it is the shell's tint.** Kvantum
draws a window's and a dialog's background from the SVG (`[Window]` and
`[Dialog]` have `interior=true`): KvMojave had `window-normal` (and
`-inactive`) at `opacity:.93`, and the dialogs' gradients starting at
`stop-opacity:.92`. `scripts/kvantum-template.py` puts
`{{ window_opacity() }}` there instead and marks those four elements
`class="tint"`, so the shell's `services/app-tint.sh` can write a new tint
into the rendered SVG whenever it changes; a theme apply renders the one the
shell last recorded. Running Qt apps take it at their next start, as they do
colours. Measured in a nested Hyprland with blur off over a white
background, Dolphin's places panel and file view: 186 grey at 0.30 and 46 at
0.90, as 22 (the background) over 255 predicts; the toolbar stays opaque, as
KvMojave draws it. `[GeneralColors]`' `window.color` (`cc`) and `base.color`
(`b3`) changed no pixel there, nor in qt6ct, even at `ff` and `4d`: they are
not the knob, and are left as they were. (Alphas there are `#RRGGBBAA`, not
Qt's `#AARRGGBB`, and `strip` drops the `#`: `#{{background | strip}}cc`.)

`QT_WAYLAND_DISABLE_WINDOWDECORATION=1` stops Qt drawing its own titlebar so
Hyprland's border and 8px rounding are the only frame.

### The Kvantum theme follows the palette, light themes included

The theme is KvMojave's: its metrics, its widget sections, its SVG. Before, only
`[GeneralColors]` followed the palette while the SVG's 70 colours and every
section's `text.*.color` stayed KvMojave's dark ones, so a light palette drew
dark text on dark fills (Dolphin under Catppuccin-Latte was unreadable). Now
both files are templates:

- **`templates/Wallust.svg` is written by `scripts/kvantum-template.py`** from
  the KvMojave.svg the kvantum package installs (the old committed SVG was that
  file, byte for byte). It replaces colours by role and leaves everything else
  as it was; rerun it if a kvantum update changes KvMojave.
  A grey became `shade(t)`, t measured against KvMojave's window (`#302f2e`)
  and text (`#ffffff`), so KvMojave's window is exactly the palette's
  background; blues became `accent(t)`, lighter or darker than the accent by as
  much as they were than KvMojave's `#286adc`; white became the text colour,
  except a check mark drawn on the accent, which takes the background; black
  stayed black, since it is only ever a shadow or an outline at low opacity.
  The window buttons' traffic lights and the shadow hints kept their colours.
  Windows and dialogs take the shell's tint where KvMojave was a little
  translucent (Translucency, above). Change a role in the script rather than
  a colour in the template.
- **Selection is an accent tint under ordinary text.** Views disagree about
  which role draws selected text: Dolphin's Places panel uses Text, its file
  view HighlightedText. KvMojave drew a light grey under both, and the Places
  panel put white text on it. So the SVG's selected and pressed rows (and menu
  and menu bar highlights) are `selection(0.4)`/`selection(0.5)`, the accent
  over the background, and Text and HighlightedText are both the foreground.
- **The palette's Highlight stays the full accent** (kdeglobals' Selection
  background, Kvantum's `highlight.color`): KDE recolours Breeze icons with it,
  and with the tint there the folders went a dull dark blue.
- Every section's text colour is `{{ foreground }}`, a `shade()` of it when
  inactive, or the accent where KvMojave used a light blue.

Verified in a nested session under plasma-integration, fresh and live, dark
(Oxocarbon-Dark) and light (Catppuccin-Latte): Dolphin, its context menu, the
KIO file dialog, and the KDE Connect app (on a fresh start).

Known and left alone: Dolphin's small status bar elides its text under Kvantum
("3 fil…(9 B)"), where Fusion shows "3 files (9 B)". It did so before the
templates too.

### Toolbars and arrows

**Toolbars and menu bars are the window's glass, their buttons flat** (the owner,
2 October: KvMojave's grey segmented button groups, on a black bar over a
window of glass, looked out of place). `[Toolbar]` and `[MenuBar]` draw no
interior or frame, so the window's background shows through (measured:
Dolphin's toolbar at alpha 107, as its views, where it was 255), and with
`group_toolbar_buttons=false` Kvantum frames an auto-raised tool button only
when it is not in its normal state: hovered, pressed or checked.

**Arrows are line chevrons**, as the shell draws them: Lucide's proportions,
in `text.muted` (`shade(0.7)`), the text colour hovered or pressed, the
disabled text disabled. `scripts/kvantum-template.py` draws them in place of
KvMojave's filled arrowheads (`tarrow`, a tool button's menu arrow;
`flat-arrow`; the combo boxes' `carrow`; a submenu's) and adds what KvMojave
lacks: `arrow-*` (the breadcrumb's, spin boxes', tree expanders') and a
submenu arrow's normal, pressed and disabled states. Kvantum draws an element
a theme lacks from its own built-in theme, in that theme's grey, whatever the
palette: Dolphin's breadcrumb arrow was `#b4b4b4`, and a highlighted menu
entry, drawn in the pressed state, fell back the same way. Checked in Dolphin
and in an offscreen gallery of the states (`QT_QPA_PLATFORM=offscreen`).

Known and left alone: a checked tool button is KvMojave's light
`tbutton-toggled` under the text colour, low in contrast on a dark palette;
Dolphin's floating status bar is opaque, as Dolphin paints it in the window
colour.

### Apps outside this

- **KeePassXC is Qt 5** (2.7). qt6ct and Kvantum here are Qt 6 only, so it
  gets neither; its own theme is set to `dark` in `keepassxc.ini`. On
  "Automatic" it follows the portal's `color-scheme`, which `apply.sh` sets.
  Following the palette itself would need `qt5ct` and `kvantum-qt5` and its
  theme on "Classic".
- **Apps with a theme of their own** (PrismLauncher, OnlyOffice's bundled Qt)
  are not on this path at all.

## GTK apps (the file dialogs, blueman)

A browser's upload and download dialogs are xdg-desktop-portal-gtk's, a GTK 3
process that runs from login (`hyprland-portals.conf` names it after
Hyprland's own portal). blueman-manager and nm-connection-editor, which the
quick settings' applet buttons open, and the applets' own prompts are GTK 3
too; zenity is GTK 4 with libadwaita. Until 2 October nothing themed them, and
GTK 3 drew its built-in Adwaita, light, whatever the palette.

| Piece | Owns | Where |
| --- | --- | --- |
| `adw-gtk-theme` (adw-gtk3) | libadwaita's look for GTK 3, drawn with libadwaita's named colours | Jupiter-installer's `packages/core.txt` |
| The Wallust GTK theme | GTK 3 apps' colours and glass; the look of GTK 4 apps without libadwaita | `templates/gtk-3.0.css`, `gtk-4.0.css`, rendered to `~/.local/share/themes/Wallust/` |
| `~/.config/gtk-4.0/gtk.css` | every GTK 4 app's colours and glass, libadwaita's included, which ignores theme names | `templates/gtk.css` |
| gsettings `gtk-theme` | which theme GTK 3 apps (and GTK 4 ones without libadwaita) load | `gtk-theme.sh` |

**Why adw-gtk3.** GTK 3's built-in Adwaita draws with literal colours: its dark
stylesheet uses colour literals 1215 times (107 different) and its named
colours 3 times, and exports 36 of them for apps to read, not to recolour it
by. adw-gtk3 draws with libadwaita's named colours (`@window_bg_color` alone
225 times), and libadwaita 1.9 feeds its CSS variables from the same names
(`--window-bg-color: @window_bg_color`), so the `@define-color`s of
`templates/gtk.css` recolour both. `gtk-3.0.css` imports it as `adw-gtk3` or
`adw-gtk3-dark` by `scheme()`, then includes `gtk.css`. The accent is the
Settings app's, as in kdeglobals; its font is not passed on, as GTK's is
gsettings' `font-name`, which Chromium-based browsers take for their own
interface too.

**The glass is one layer**, as in Kvantum. Every `.background` (each window
and dialog, but not popovers, tooltips or the windows menus open in, `.popup`)
is the background at the shell's tint, in the lines marked `/* glass */`,
which `app-tint.sh` rewrites. Everything inside a window is transparent,
the window's own colour included, which toolbars, menu bars and tab bars paint
again: blueman's menu bar and toolbar were darker bands until it was.
Transparent at the text's colour, not black's: GTK 3's `mix()` does not
premultiply, and adw-gtk3 fills buttons and entries with `mix(fg, surface,
0.9)`, which with transparent black came out as a dark smudge at half alpha
(the file dialog's path bar); with the text's colour it is the text at 10%,
as the shell's pills are. GTK 3 draws a window's background below a
client-side title bar, not under it (measured: alpha 0 in the file dialog's
header), so `gtk-3.0.css` gives title bars the glass of their own. Menus,
popovers and libadwaita's dialogs are solid (`shade(0.06)`): they lie over the
window's own content, which no blur reaches, and Kvantum's menus nearly are
(90%).

**Running GTK 3 apps load the theme again when it is named anew**, the portal
among them, which otherwise kept the theme it started with until the next
login. Naming the theme already named does nothing: dconf drops a write that
changes nothing (measured: a repeated `gsettings set` sent no notification;
only the first, from unset, did). So the theme has a second name,
`Wallust-2`, a link to the same folder, and `gtk-theme.sh` names the one not
in use: after `apply.sh` renders, and with `--reload` (only while one of the
two is named, so a theme picked by hand stays) after `app-tint.sh` writes a
tint. GTK 4 reads `~/.config/gtk-4.0/gtk.css` once per app, at start.

Verified on 2 October on a workspace not shown, captured with `grim -T` (alpha
kept): a GTK 3 file chooser and blueman-manager from a scratch theme, zenity's
list (libadwaita), all glass at alpha 107 for a 0.42 tint, headers included; a
running GTK 3 app re-tinted as the theme was renamed (107, 230, 76, 107); and
the session's own portal, running since login, showing an `OpenFile` request
in the theme after `apply.sh`. `tests/app-tint-test.py` and
`tests/wallust-templates-test.py` (GTK's own parsers read the rendered CSS)
cover the files.

## Hyprland blur rules

`config/hypr/styles/layout.lua` blurs by layer-shell namespace. The shell's
popups are matched by pattern:

```lua
match = { namespace = "^quickshell:.*-popup$" }
```

so **a new `WidgetPopup` must use a `namespaceSuffix` ending in `-popup`** or it
renders as a flat panel next to blurred ones. `TrayMenu` is `"tray-popup"` for
exactly this reason.

## Packages

Required: `dolphin`, `qt6-wayland`, `qt6ct`, `kvantum`, `breeze-icons` and
`adw-gtk-theme`, all in Jupiter-installer's `packages/core.txt`, which its
phase 2 installs. Nothing
from Plasma: `plasma-integration` needs `xdg-desktop-portal-kde`, which needs
`plasma-workspace`, and with it KWin and 66 packages more, and adds a Plasma
session to the login screen.

`imagemagick` is only needed by wallust's `wal` backend. `apply.sh --from` runs
`wallust run` on the default `fastresize` backend, which does not use it.

`wallust` comes from the AUR (Jupiter-installer's `packages/aur.txt`); on the desktop it is still a
cargo install in `~/.cargo/bin`, which `apply.sh` puts first on its PATH. The Wallpapers tab's "Add from file…" needs `zenity`.
`apply.sh` also runs `python3` (the kdeglobals merge) and `gsettings` (glib2);
the portal reads `color-scheme` through
`xdg-desktop-portal-gtk`, which `hyprland-portals.conf` names after
Hyprland's own.
