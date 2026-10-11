# Jupiter-dotfiles

Dotfiles by @skullduggery and @lwctr, usually set up with [Jupiter-installer](https://codeberg.org/skullduggery/Jupiter-installer).

To use your own configuration it is recommended to create a fork and clone that and symlink it. 
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
| `scripts/check.sh` | The project's validation: formatting (QML, Python, shell, Lua), the linters for each (qmllint, ruff and mypy, shellcheck, lua-language-server against Hyprland's API), qmldir entries, popup blur names, icon glyphs, JSON and TOML, both Hyprland configs, and the tests below, which have to run every helper script. `--fix` formats first, `--staged` only looks at staged files. It names the packages of any tool that is missing. |
| `scripts/install-hooks.sh` | Run once per clone; afterwards a commit formats and checks the staged files, and a push runs the full `check.sh`. |
| `scripts/install-greeter.sh` | Copies the login screen, the shell's colours, the monitor layout (with the changes kept in Settings) and the current wallpaper into `/etc/greetd`, plus its PAM files (run with `sudo`, and again after changing any of those). |
| `scripts/quickshell-types.py` | Writes a copy of Quickshell's type information with its packaging mistakes fixed, which `check.sh` lints against so Quickshell types get checked too. |
| `scripts/pasted-glyphs.py` | Lists QML files with a pasted private-use (icon) character; icons are written as `\u{...}` escapes, which no tool can silently delete. |
| `scripts/kvantum-template.py` | Rebuilds the Kvantum theme's SVG template from the KvMojave theme that comes with Kvantum, so Qt apps follow light themes too, with line chevrons for its arrows. Run it again if a Kvantum update changes KvMojave. |

| Test | What it checks |
|---|---|
| `tests/apply-test.py` | Applying a theme with `apply.sh`: to everything or the shell alone, again as it was last time, from a saved scheme or from an image. |
| `tests/app-tint-test.py` | The apps' glass: `app-tint.sh` writing the shell's tint for kitty, into Kvantum's SVG and the GTK stylesheets, and naming the GTK theme anew so running GTK 3 apps load it again. |
| `tests/autostart-test.py` | The Settings app's About → Startup tab: which autostart apps start under Hyprland, as systemd decides, and switching one off and on again leaving nothing behind. |
| `tests/displays-test.py` | The Settings app's Displays page: the monitor rules it applies and keeps, and `monitors.lua` applying the kept ones after its own. |
| `tests/hypridle-restart-test.py` | Restarting hypridle on a new config stops only this session's, never another one's. |
| `tests/greeter-env-test.py` | The login screen's list of users and sessions, each session with the command greetd starts. |
| `tests/kvantum-template-test.py` | The Kvantum template is what `kvantum-template.py` makes of the installed KvMojave, so a Kvantum update that changed it shows. |
| `tests/install-greeter-test.py` | Runs `install-greeter.sh` into a temporary folder and checks the result stands on its own: no symlinks, the session's monitor layout, a compositor config Hyprland accepts. |
| `tests/nextcloud-principal-test.py` | The calendar finding your Nextcloud user id however it is spelled, and refusing to send the password over plain http. |
| `tests/nextcloud-tasks-test.py` | The calendar's open tasks, dated or not, from task lists and calendars alike, in the order the dropdown lists them, against a stand-in Nextcloud. |
| `tests/palettes-test.py` | The Settings app's theme list: saved schemes first, every palette complete, and a theme wallust cannot render left out. |
| `tests/qml-test.py` | The QML tests in `tests/qml/`, run inside Quickshell offscreen with nothing of the session around them: colours, the greeter's `style/`, idle times, keybind rows, calendar addresses, unlocking with a finger, the launcher leaving out removed apps. |
| `tests/screen-record-test.py` | Screen Record's file in `Videos/Recordings`, and the recording ending with the shell. |
| `tests/shelf-test.py` | The shelf: pasting text, images and copied files without overwriting, refusing a password manager's copy, notes named after their first line, copying back. |
| `tests/wallpaper-import-test.py` | Adding a wallpaper: copied into the library, the same image once, another one under a taken name numbered. |
| `tests/wallust-templates-test.py` | Every colour template renders for a dark and a light theme (the GTK ones read by GTK's own parsers too), and updating `kdeglobals` keeps what KDE apps wrote there. |

`check.sh` runs the tests; each also runs alone with `python3 tests/<name>.py`.

## Login screen

The greeter is copied rather than symlinked, because greetd runs it as the `greeter` user, which cannot read your home directory. To use it on a machine:

```bash
sudo pacman -S greetd
sudo scripts/install-greeter.sh
sudo systemctl disable sddm      # or whichever display manager is enabled
sudo systemctl enable greetd
```

It takes over at the next boot. If it does not come up, Ctrl+Alt+F2 gives you a text login to switch back with `sudo systemctl disable greetd && sudo systemctl enable sddm`.
