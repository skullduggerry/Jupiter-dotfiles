# TODO

Only what is actually open. Finished phases were removed — `git log` has them.

## Untested paths

Built and reviewed, never exercised against the real thing:

- [ ] Joining a **Wi-Fi network that needs a PSK**: `connectWithPsk()` and the
      wrong-password path. The half in front of them is verified — clicking
      *Connect* on an unknown network raises the prompt, it takes keystrokes,
      and Escape dismisses the prompt without closing the dropdown. The rest
      needs a real association, so it wants a network you own.
- [ ] The **three-finger swipe gesture** itself.
- [ ] How the **two-finger swipe** feels on the real touchpad. It is now
      driveable from a virtual pointer — a uinput device has to advertise
      `REL_*WHEEL_HI_RES` for libinput to deliver the events, which is why an
      earlier attempt concluded wheel could not be injected — so the paging
      thresholds were tuned against a replay of the measured gesture. Only the
      feel is unconfirmed.

## Next features

- [ ] **Settings app** as a `FloatingWindow`: theme, accent colour, font,
      persisted through `FileView` + `JsonAdapter` and applied live. Every
      widget already reads `Colors.*`/`Style.*`, so deriving those from a config
      file is contained — but a Light mode means authoring a second palette,
      since every colour today assumes dark.
- [ ] **Tray flyout**: six quick-toggle tiles. Backends present here:
      `hyprsunset` (Night Light), `power-profiles-daemon` (Power Mode), `rfkill`
      (Airplane Mode), and DND (`NotificationService.doNotDisturb`, already
      toggled by right-clicking the bell). **Not
      installed: `cliphist`** and **no screen recorder** (`wf-recorder` /
      `wl-screenrec`) — those two tiles need a package first.
- [ ] **Wallpaper selector**, plus the wallpaper section of the workspace
      dropdown, over `hyprpaper` IPC, including per-workspace apply.
- [ ] The bar's **tray-expand** button, once its panel exists. (The
      notification bell is in.)
- [ ] **Inline reply** on notifications that offer it. `hasInlineReply` /
      `sendInlineReply()` exist; the capability is deliberately not advertised
      until there is a field to type into.
- [ ] Toasts on the **focused** monitor: the mechanism is verified against a
      `hyprctl output create headless` second screen — the toast moves with
      focus and back, and the move does *not* restart its expiry timer (a 10s
      toast still expired at 10.2s across two moves). What is left is the
      subjective half: it jumps with no transition, so judge that on real
      dual-monitor hardware.
- [ ] The design file's **search box**, if it should replace the fullscreen
      launcher rather than sit alongside it.

## Dolphin / Qt theming

Done and verified against a real window — see `.github/THEMING.md`. Left over:

- [ ] Other Qt/KDE apps inherit this for free but none were checked. Ark,
      Gwenview and the KIO file dialogs are the ones worth a look.
- [ ] `wallust.toml` mixes `target=` (kitty, kdeglobals, kvantum) and `dst=`
      (nvim). Both work; pick one.
- [ ] `backend`/`palette` in `wallust.toml` are inert now that the palette comes
      from a built-in theme. Harmless, but they read as if they were live.
