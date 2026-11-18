# Jupiter-dotfiles

Desktop system based on Quickshell and Hyprland, for Arch and NixOS. Custom theming support as well as in-depth customisation.
By @skullduggery and @lwctr.

Part of Jupiter: [Jupiter-installer](https://github.com/skullduggerry/Jupiter-installer) sets these dotfiles up, and [Jupiter-testing](https://github.com/skullduggerry/Jupiter-testing) lints and tests them.

## Contents

| Path | Purpose |
|---|---|
| `.config/quickshell/` | The shell: bar, OSD, lock screen, notifications, quick menu, Settings app |
| `.config/hypr/` | Hyprland, configured in Lua: keybinds, monitors, window rules, autostart |
| `.config/wallust/` | The theme, rendered for the shell, kitty, nvim, Qt and GTK apps |
| `.config/kitty/`, `nvim/`, `Kvantum/`, `uwsm/`, … | The apps' own configs |
| `etc/`, `scripts/` | The login screen and the system files, installed as root |

## Development

```bash
./check.sh                                    # lint and test this repo (--fix formats first)
./check.sh check all                          # all three: dotfiles, installer, testing
./check.sh lint                               # or test: one half (./check.sh --help)
../Jupiter-testing/scripts/install-hooks.sh   # once: format, lint and test before each push
```

Tests and Linters are found in Jupiter-testing, and can be run with check.sh from each repositories root.

GitHub Actions checks every push and pull request against both systems the installer supports (`.github/workflows/check.yml`): this repo's linters and suites on Arch, and on NixOS its Hyprland config checked by NixOS's Hyprland and its QML run in NixOS's Quickshell. The installer's own Actions check it with these dotfiles.

## Documentation

- [The wiki](https://github.com/skullduggerry/Jupiter-dotfiles/wiki): installing, the login screen, themes, the scripts, development.
- [CLAUDE.md](CLAUDE.md): how the shell is built, where things go, the theme and the rules it follows; written for coding with Claude.
