# TODO

Only what is actually open. Finished work is in `git log`.

## To try by hand

Everything below was built and driven in a nested Hyprland with a virtual
pointer and keyboard (and a stand-in BlueZ for Bluetooth, see
PROJECT_STRUCTURE.md); what is left needs real hands, eyes or hardware.

- [ ] A **real pointer and keyboard** over the shell: the toggle tiles, every
      Settings page with SUPER+I and SUPER+W pressed rather than fired, the
      arrow keys between dropdown zones, the pills and the usage meters.
- [ ] **Bluetooth with a real device**: pairing one (and a PIN or passkey
      one, which goes through blueman-applet's agent), forgetting it, and
      pairing from a phone with "visible to other devices" on. Against the
      stand-in: search while shown and not after, pair, cancel, connect,
      forget on the second click, power off and on.
- [ ] Joining a **Wi-Fi network that needs a PSK** and the wrong-password path;
      the prompt itself is verified. Needs a network you own.
- [ ] **Airplane Mode** switching the radios: the desktop's only link is Wi-Fi.
- [ ] **Night Light by eye**: the tint is applied after screen capture, so
      4000 K has only been read back from hyprsunset, never looked at.
- [ ] The **touchpad**: the three-finger swipe, and how the two-finger swipe's
      paging feels (it was tuned against a replay of the measured gesture).
- [ ] **Displays on the real monitors**: a real mode and refresh-rate change,
      adaptive sync and a display switched off.
- [ ] **Sound**: picking another output or input device.
- [ ] **Startup** at a real login: an app added and one switched off.
- [ ] **Add from file…** with the real zenity dialog.
- [ ] **This Workspace** wallpapers on two real monitors, and a login with
      some set.
- [ ] The **greeter on both of the desktop's screens** (it has booted there;
      whether it drew on both is not in any log).
- [ ] **Monitors unplugged** with per-monitor workspaces: one switched off and
      on, both at once, the laptop meeting a display for the first time. The
      laptop's HDMI-A-1 is now placed `auto-right`, which should close the gap
      its fixed x=1920 left beside eDP-1 at scale 2: check SUPER+CTRL+arrows
      and the pointer crossing there.
- [ ] **Inline reply** from a real app (only a gdbus `Notify` has sent one).
- [ ] **Toasts following focus** on two monitors: the fade-in, and typing in
      an app on the other monitor while a toast follows.
- [ ] The **media player with real players**: Spotify's and YouTube Music's
      apps (neither is installed here), YouTube, YouTube Music and Spotify in
      Brave Origin (only a local page has played there), and the media keys
      on a real keyboard.
- [ ] **Keyboard layouts** typed on a real keyboard (us and de are kept on the
      desktop; the K8 is two devices): the bar, SUPER+SPACE and a click, and the
      login screen on the first after `scripts/install-greeter.sh` runs again.
      The laptop has none kept yet: Settings → Keyboard there.
- [ ] The **small bar on the real monitors**: Settings → Displays → Main bar
      on HDMI-A-1 and back, Over windows with a window maximised under the
      pill, a game fullscreen on the full bar's screen with Caffeine on, and
      the full bar's monitor switched off and on.
- [ ] The **blur slider** by eye on the real monitors (NVIDIA): its two ends
      over a busy wallpaper, and whether a high size costs frames while
      dragging windows. Only a nested Hyprland has taken it.
- [ ] The **tint slider, kitty and Qt apps** by eye: drag it with a kitty
      open beside the Settings app (open kittys need one restart first, for
      the socket), reopen Dolphin after a change (only a white background with
      blur off has shown it), a light theme's own value, and Adaptive over a
      bright wallpaper (only an injected backdrop has raised it in a test).

## Qt theming

Qt apps take their style, icons and fonts from qt6ct and their colours from
the Wallust colour scheme; see `.github/THEMING.md`. The palette they get
matches what plasma-integration gave them, for a dark and a light theme, and
Dolphin is themed on a fresh install. Left over:

- [ ] Qt apps in the **live** session by eye: Dolphin's menus, the KIO file
      dialog and KDE Connect were last checked under plasma-integration.
- [ ] **Running Qt apps** take a new theme's colours only when reopened;
      qt6ct applies the icons and the font at once.
- [ ] Dolphin's small **status bar elides** under Kvantum ("3 fil…(9 B)");
      Fusion shows it whole. It did so before the templates.
- [ ] **KeePassXC** is Qt 5 and outside all of this; its theme is set to
      `dark`. Following the palette would need `qt5ct` and `kvantum-qt5` —
      your call.
- [ ] Ark and Gwenview are not installed, so they were not looked at.
