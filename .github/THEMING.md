# Theming — agent reference

How colour gets to every app in this repo. `.github/PROJECT_STRUCTURE.md`
covers the quickshell shell itself.

## The chain

```
wallust built-in theme "Oxocarbon-Dark"
        │
        ▼  config/wallust/apply.sh  ← run at login by modules/start.lua
   wallust theme Oxocarbon-Dark
        │
        ├─ templates/kitty.conf       → ~/.config/kitty/colors.conf              (gitignored)
        ├─ templates/nvim.lua         → ~/.config/nvim/lua/colors.lua            (gitignored)
        ├─ templates/kdeglobals       → ~/.config/kdeglobals                     (outside the repo)
        └─ templates/Wallust.kvconfig → ~/.config/Kvantum/Wallust/Wallust.kvconfig (gitignored)
```

**The palette is a fixed theme, not derived from the wallpaper.** This is easy
to get wrong: the config *looks* like a pywal setup (`backend = "wal"`, a
wallpaper in hyprpaper.conf), but running `wallust run ~/Wallpapers/whale.jpg`
replaces the whole palette with a washed-out monochrome blue. The live colours
are exactly `wallust theme Oxocarbon-Dark`, verified byte-for-byte against
`colors.conf`. `backend`/`palette` in `wallust.toml` only matter for
image-derived runs and are inert for `theme`.

Override the theme for one run with `WALLUST_THEME=... apply.sh`;
`wallust theme <name> --preview` shows a palette without writing anything.

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

Colours are applied at app start — a running Dolphin does not repaint when
wallust regenerates kdeglobals.

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

`imagemagick` is only needed by `backend = "wal"`, i.e. by `wallust run` on an
image. Nothing in this repo takes that path any more.
