# Jupiter-dotfiles

A desktop for Arch Linux: Hyprland with a shell of its own, written in QML on Quickshell (bar, lock and login screen, notifications, quick menu, Settings app), and the configs of the apps around it, all coloured from one wallust theme. By @skullduggery and @lwctr.

Part of Jupiter: [Jupiter-installer](https://github.com/skullduggerry/Jupiter-installer) sets these dotfiles up, and [Jupiter-testing](https://github.com/skullduggerry/Jupiter-testing) lints and tests them.

## Installing

On an Arch install of your own, as your user:

```bash
git clone https://github.com/skullduggerry/Jupiter-installer.git ~/Jupiter-installer
~/Jupiter-installer/bootstrap.sh 2 3 4
```

Then reboot. Phase 4 clones this repo into your home and links each folder of `.config/` into `~/.config/`, moving whatever was in the way to `~/.dotfiles-backup/`. Running it again only does what is missing. To keep your own changes, fork this repo and point the installer at your fork ([Customising](https://github.com/skullduggerry/Jupiter-dotfiles/wiki/Customising)).

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
../Jupiter-testing/scripts/install-hooks.sh   # once: check on every commit and push
```

Each Jupiter repo has this `check.sh`, with the same arguments. The linters and tests live in Jupiter-testing, which it clones next to this repo if it is missing.

## Documentation

- [The wiki](https://github.com/skullduggerry/Jupiter-dotfiles/wiki): installing, the login screen, themes, the scripts, development.
- `.github/`: how the shell is built and the rules it follows (`PROJECT_STRUCTURE.md`, `THEMING.md`, and `llm.md` for coding agents).
