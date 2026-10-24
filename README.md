# Jupiter-dotfiles

Dotfiles by @skullduggery and @lwctr, usually set up with [Jupiter-installer](https://codeberg.org/skullduggery/Jupiter-installer).

To use your own configuration it is recommended to create a fork of the project,clone it onto your machine and symlink to the relevant folders. 
Any changes in the dotfiles can then simply be pushed and reused upon reinstall, this is made easier by adding the link to your fork to `jupiter/config.py` in the installer.

## Installing

[Jupiter-installer](https://codeberg.org/skullduggery/Jupiter-installer) sets these dotfiles up. Its phase 2 installs the packages they need, and its phase 4 clones them into your home, links every folder in `.config/` into `~/.config/` and `.config/.zshrc` to `~/.zshrc` (moving whatever was in the way to `~/.dotfiles-backup/<time>/`), renders the default theme, Oxocarbon-Dark, for kitty, nvim, Qt and GTK apps and the shell, installs the login screen and enables greetd unless another display manager is enabled (see "Login screen" for switching), and makes zsh your login shell. On an Arch install of your own, as your own user (it asks for sudo where it needs it):

```bash
git clone https://codeberg.org/skullduggery/Jupiter-installer.git ~/Jupiter-installer
~/Jupiter-installer/bootstrap.sh 2 3 4
```

Then reboot. Running phase 4 again only does what is missing. To work on the dotfiles, run `scripts/install-hooks.sh` once in the clone. Wallpapers are not part of the repo: Settings → Appearance → Wallpapers shows `~/Wallpapers`, which can be a link to a synced folder (`ln -s ~/Nextcloud/Home/Wallpapers ~/Wallpapers`), and the login screen shows the chosen one once `scripts/install-greeter.sh` runs again.

## Contents

| Folder | Description |
|---|---|
| **hypr** | Hyprland window manager configuration — keybinds, monitor setup, window rules, autostart. |
| **quickshell** | Quickshell-based shell setup — bar, OSD, lock screen and the rest of the UI. The volume/brightness OSD lives here now; swayosd is gone. |
| **kitty** | Terminal emulator configuration, including wallust-generated color integration. |
| **wallust** | Color palette generation from wallpaper, templated out to other configs (e.g. kitty). |
| **nvim** | Neovim configuration, following the wallust colours live. |
| **Kvantum** | The Qt widget style Dolphin and other Qt apps are drawn with; its colours are rendered by wallust. |
| **uwsm** | The session's environment (the Qt theme variables), read by uwsm when it starts Hyprland. Symlink it to `~/.config/uwsm` like the others. |

## Scripts and tests

Everything runs from the repo root.

| Script | What it does |
|---|---|
| `scripts/check.sh` | The project's validation: formatting (QML, Python, shell, Lua), the linters for each (qmllint, ruff and mypy, shellcheck, lua-language-server against Hyprland's API), qmldir entries, popup blur names, icon glyphs, JSON and TOML, both Hyprland configs, and the tests (Jupiter-testing, below), which have to run every helper script. `--fix` formats first, `--staged` only looks at staged files. It names the packages of any tool that is missing. |
| `scripts/install-hooks.sh` | Run once per clone; afterwards a commit formats and checks the staged files, and a push runs the full `check.sh`. |
| `scripts/install-greeter.sh` | Copies the login screen, the shell's colours, the monitor layout (with the changes kept in Settings) and the current wallpaper into `/etc/greetd`, plus its PAM files (run with `sudo`, and again after changing any of those). |
| `scripts/quickshell-types.py` | Writes a copy of Quickshell's type information with its packaging mistakes fixed, which `check.sh` lints against so Quickshell types get checked too. |
| `scripts/pasted-glyphs.py` | Lists QML files with a pasted private-use (icon) character; icons are written as `\u{...}` escapes, which no tool can silently delete. |
| `scripts/kvantum-template.py` | Rebuilds the Kvantum theme's SVG template from the KvMojave theme that comes with Kvantum, so Qt apps follow light themes too, with line chevrons for its arrows. Run it again if a Kvantum update changes KvMojave. |

The tests are a repo of their own, Jupiter-testing, cloned next to this one (or wherever `JUPITER_TESTING` points). They run every helper script against stand-in commands in a temporary home, the QML logic inside Quickshell, and the lock and login screens against stand-in PAM stacks and a stand-in greetd. `check.sh` runs this repo's share of them; its README says how to run one on its own.

## Login screen

The greeter is copied rather than symlinked, because greetd runs it as the `greeter` user, which cannot read your home directory. To use it on a machine:

```bash
sudo pacman -S greetd
sudo scripts/install-greeter.sh
sudo systemctl disable sddm      # or whichever display manager is enabled
sudo systemctl enable greetd
```

It takes over at the next boot. If it does not come up, Ctrl+Alt+F2 gives you a text login to switch back with `sudo systemctl disable greetd && sudo systemctl enable sddm`.
