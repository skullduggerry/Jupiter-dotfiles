# Theming — agent reference

How colour gets to every app in this repo. `.github/PROJECT_STRUCTURE.md`
covers the quickshell shell itself.

## The chain

```
the wallpaper app's Themes page, or apply.sh by hand
        │
        ▼  config/wallust/apply.sh [--shell-only] THEME | --from IMAGE
   wallust theme THEME          a built-in
   wallust cs THEME.json        one of colorschemes/, the repo's own
        │
        ├─ templates/quickshell.json  → ~/.cache/wallust/quickshell.json          (the shell's palette)
        ├─ templates/kitty.conf       → ~/.config/kitty/colors.conf              (gitignored)
        ├─ templates/nvim.lua         → ~/.config/nvim/lua/colors.lua            (gitignored)
        ├─ templates/kdeglobals       → ~/.config/kdeglobals                     (outside the repo)
        └─ templates/Wallust.kvconfig → ~/.config/Kvantum/Wallust/Wallust.kvconfig (gitignored)

   then $XDG_STATE_HOME/wallust/theme: the theme's name, then "all" or "shell-only"
```

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
| New kitty, nvim, Dolphin windows | at start, from the files above |
| Running Qt/KDE apps on a palette-driven style (Breeze, Fusion) | at once: `apply.sh` broadcasts `org.kde.KGlobalSettings.notifyChange(0, 0)` |
| A running Dolphin on Kvantum, as configured here | not at all, until it is reopened |
| A running nvim | not at all; `colors.lua` is read at start |

The broadcast is what plasma-integration's platform theme listens for
(`KHintsSettings::slotNotifyChange`): it reparses kdeglobals and sets the new
palette. Verified with a Dolphin on `-style fusion`, which went from
Oxocarbon-Dark to Catppuccin-Latte in place. Kvantum ignores it, because it
draws from its own theme, loaded when the style is created; and the
`StyleChanged` notification would not recreate the style either, since the
platform theme skips `setStyle()` when the style's name has not changed.

### Template filters

Wallust 3.5.1. Confirmed present: `strip` (hex without `#`), `rgb` (`29,31,33` —
what kdeglobals wants), `red`/`green`/`blue`, `lighten(f)`, `darken(f)`,
`saturate(f)`, `complementary`. **Not** present: `rgba`, `invert`, `grey`.

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

Four pieces, each owning something different. Getting any one wrong looks like
"the theme just doesn't apply".

| Piece | Owns | Where |
| --- | --- | --- |
| `QT_QPA_PLATFORMTHEME=kde` | applies the colour scheme to the palette | `config/hypr/modules/env.lua` |
| kdeglobals | colours, fonts, icon theme, **and which widget style** | `templates/kdeglobals` |
| Kvantum theme | window translucency | `templates/Wallust.kvconfig` + `config/Kvantum/Wallust/Wallust.svg` |
| Hyprland `decoration:blur` | the blur behind it | `styles/layout.lua` |

Three things cost real time here, all established by experiment:

> **`~/.config/kdeglobals` on its own does nothing.** Dolphin launched with no
> platform theme, and again with `-style breeze`, stayed fully light Breeze with
> a complete dark `[Colors:*]` in kdeglobals. Setting `[Colors:View]
> ForegroundNormal` to pure red changed nothing either — proof the file was
> never read. A platform theme is what turns a colour scheme into the
> application's `QPalette`.

> **`QT_QPA_PLATFORMTHEME=qt6ct` is the wrong platform theme for this.** It
> applies qt6ct's own font and style but does not read kdeglobals, so KDE
> widgets (Dolphin's Places panel, the file view, the breadcrumb) fell back to
> unreadable dark-grey-on-dark. `kde` — the plasma-integration plugin, already
> installed here — is the one that reads kdeglobals. qt6ct is not used at all
> and its config was removed.

> **`widgetStyle` lives in the `[KDE]` group, not `[General]`.** With it in the
> wrong group the colours were correct but the window was opaque, because
> Kvantum was never selected and Breeze was painting.

**Translucency**: Kvantum's `[%General] translucent_windows=true` +
`composite=true`, which makes only the window *background* translucent — text
and icons stay opaque, the same deal as kitty's `background_opacity 0.6`. Do
**not** use `reduce_window_opacity`: that fades the whole window, text included.
Hyprland blurs any translucent window already, so no window rule is needed.

The alpha lives in `[GeneralColors]` in the Kvantum template, as `#RRGGBBAA`
(**not** Qt's `#AARRGGBB` — confirmed against KvMojave's `base.color=#242424cc`).
`window.color` is `cc` (80%) and `base.color` `b3` (70%); those two suffixes are
the knobs to tune. Note `strip` drops the leading `#`, so an alpha value has to
be written `#{{background | strip}}cc`.

The theme is KvMojave's SVG with `[GeneralColors]` replaced by the palette; every
metric and widget section is KvMojave's, because they belong to that SVG.
`Wallust.svg` is committed, the generated `Wallust.kvconfig` is gitignored.

`QT_WAYLAND_DISABLE_WINDOWDECORATION=1` stops Qt drawing its own titlebar so
Hyprland's border and 8px rounding are the only frame.

A running Dolphin does not repaint when a theme is applied: Kvantum loads its
theme when the style is created, and ignores the palette broadcast (see "What
changes live"). Reopening it is enough.

**Light themes do not work in Dolphin with this Kvantum theme.** Only
`[GeneralColors]` follows the palette; the SVG is KvMojave's, with 67 colours of
dark fills baked in, and those draw the window and view backgrounds. A light
palette therefore puts dark text on dark surfaces: a fresh Dolphin under
Catppuccin-Latte was unreadable. The same Dolphin on `-style fusion` was
correct, and followed the theme live. Two ways out, and it is a choice between
them: a palette-driven style such as Breeze as `widgetStyle` (live updates,
light themes, but no translucency), or the SVG's fills made a wallust template
too (keeps both, and means mapping those 67 colours onto the palette).

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

Required and installed: `dolphin`, `breeze`, `breeze-icons`, `kio`,
`qt6-wayland`, `kvantum`, and `plasma-integration` (the `kde` platform theme —
it was already present, which is why qt6ct turned out to be unnecessary).

`imagemagick` is only needed by wallust's `wal` backend. `apply.sh --from` runs
`wallust run` on the default `fastresize` backend, which does not use it.

`wallust` itself is a cargo install (`~/.cargo/bin`), not a package; see the
PATH note in `apply.sh`. The wallpaper app's "Add from file…" needs `zenity`.
