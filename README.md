# Jupiter-dotfiles

A desktop for Arch Linux: Hyprland with a shell of its own, written in QML on Quickshell (bar, lock and login screen, notifications, quick menu, Settings app), and the configs of the apps around it, all coloured from one wallust theme. By @skullduggery and @lwctr.

Part of Jupiter: [Jupiter-installer](https://github.com/skullduggerry/Jupiter-installer) sets these dotfiles up, and [Jupiter-testing](https://github.com/skullduggerry/Jupiter-testing) lints and tests them.

## Installing

On an Arch or NixOS install of your own, as your user:

```bash
git clone https://github.com/skullduggerry/Jupiter-installer.git ~/Jupiter-installer
~/Jupiter-installer/bootstrap.sh 2 3 4
```

Then reboot. Phase 4 clones this repo into your home and links each folder of `.config/` into `~/.config/`, moving whatever was in the way to `~/.dotfiles-backup/`. Running it again only does what is missing. To keep your own changes, fork this repo and point the installer at your fork ([Customising](https://github.com/skullduggerry/Jupiter-dotfiles/wiki/Customising)).

On NixOS the same installer and the same commands set them up: it tells which system it is on, and there its flake declares what phase 4 installs as root on Arch (its `docs/nixos.md`); the system's PAM stacks are left alone by `scripts/install-greeter.sh` where they are links, as NixOS's are.

## Contents

| Path | What |
|---|---|
| `.config/quickshell/` | The shell: bar, OSD, lock screen, notifications, quick menu, Settings app |
| `.config/hypr/` | Hyprland, configured in Lua: keybinds, monitors, window rules, autostart |
| `.config/wallust/` | The theme, rendered for the shell, kitty, nvim, Qt and GTK apps |
| `.config/kitty/`, `nvim/`, `Kvantum/`, `uwsm/`, … | The apps' own configs |
| `etc/`, `scripts/` | The login screen and the system files, installed as root |

Wallpapers are not part of the repo: Settings → Appearance → Wallpapers shows `~/Wallpapers`, which can be a link to a synced folder.

## Development

```bash
./check.sh                                    # lint and test this repo (--fix formats first)
./check.sh check all                          # all three: dotfiles, installer, testing
./check.sh lint                               # or test: one half (./check.sh --help)
../Jupiter-testing/scripts/install-hooks.sh   # once: format, lint and test before each push
```

Each Jupiter repo has this `check.sh`, with the same arguments. The linters and tests live in Jupiter-testing, which it clones next to this repo if it is missing.

GitHub Actions checks every push and pull request against both systems the installer supports (`.github/workflows/check.yml`): this repo's linters and every Jupiter repo's suites on Arch, and on NixOS the installer's flake built with these dotfiles, their Hyprland config checked by NixOS's Hyprland and their QML run in its Quickshell. The pre-push hook runs the Arch half before a push.

## Documentation

- [The wiki](https://github.com/skullduggerry/Jupiter-dotfiles/wiki): installing, the login screen, themes, the scripts, development.
- [AGENTS.md](AGENTS.md): how the shell is built, where things go, the theme and the rules it follows; written for coding agents, and read by Claude Code through `CLAUDE.md`.
