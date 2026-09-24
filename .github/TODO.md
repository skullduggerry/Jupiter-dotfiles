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
- [ ] **Airplane Mode** actually switching the radios. Reading it is verified;
      flipping it is not, because the desktop's only link is Wi-Fi and the
      test would have cut the connection it was running over. The write is the
      same `Networking.wifiEnabled` the Wi-Fi page's On/Off header makes.
- [ ] **Night Light by eye.** Everything but the colour is verified in a nested
      Hyprland (see "Quick toggles" in PROJECT_STRUCTURE.md); the tint is
      applied after screen capture, so 4000K has never been looked at.
- [ ] The toggle tiles under a **real pointer**. They were driven through IPC,
      since a nested compositor has no input to give them.
- [ ] The **wallpaper app** under a real pointer and keyboard, for the same
      reason: its services were driven through test-only IPC hooks, its pages
      switched the same way, and only Escape and typing into the theme search
      went through real (injected) keys. SUPER+W itself was fired as the
      global, not pressed.
- [ ] **Add from file…** with the real zenity dialog. The import script was
      exercised with a stand-in zenity: new file, same file again, a name
      clash, and cancelling.
- [ ] A **real login** with the new start-up: hyprpaper started from the saved
      config (only simulated, with `hyprpaper -c` on it), and the login-time
      `apply.sh`, which only now finds wallust at all.

## Next features

- [ ] **Settings app** as a `FloatingWindow`: accent colour and font. The
      theme part exists now, as the wallpaper app's Themes page, and a light
      palette already works in the shell (every colour is derived from
      `Colors.palette`), so the design's Light/Dark/Auto is a choice of theme.
- [ ] The tray flyout's last two tiles, **Clipboard** and **Screen Record**.
      The other four are the Toggles page. Both need a package first:
      **`cliphist` is not installed**, and **no screen recorder** is
      (`wf-recorder` / `wl-screenrec`). Each is one more `ToggleTile` in
      `panels/TogglesPanel.qml`; at six tiles `Style.toggles.tileColumns` goes
      to 3, which is the design's grid.
- [ ] The rest of the **wallpaper app**'s design: "This Workspace / All
      Workspaces" (hyprpaper takes a monitor, not a workspace, so per-workspace
      means switching on workspace changes), the category tabs (subfolders of
      `~/Wallpapers` would fit), and the wallpaper section of the workspace
      dropdown.
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
- [ ] **Decide how Dolphin should follow a theme.** With Kvantum it takes a new
      theme only when reopened, and a light theme is unreadable in it, because
      KvMojave's SVG draws dark surfaces whatever the palette says. Breeze as
      the widget style follows every theme live (verified with Fusion) but
      loses the translucency; making the SVG a template keeps both. See
      "Qt / KDE apps" in THEMING.md.
- [ ] A running **nvim** keeps its colours until restarted; `colors.lua` is
      only read at start.
