#!/usr/bin/env bash
# Install the quickshell greeter where greetd's unprivileged `greeter` user can
# read it.
#
#     scripts/install-greeter.sh [destination]      default: /etc/greetd
#
# This exists because $HOME is 0700: the greeter user cannot read the shell's
# config, its style/ folder or the wallpaper, so all three are copied out of the
# home directory rather than symlinked into it.
#
# style/ is copied rather than duplicated in the repo, so .config/quickshell/
# stays the single source of truth for the design system. Re-run this after
# changing any colour or dimension, or the greeter keeps the old ones. The same
# goes for the monitor layout: etc/greetd/monitors.lua is a symlink to
# .config/hypr/modules/monitors.lua, and `install` copies what it points at.
# What the Settings app kept for the monitors on this machine is appended to
# that copy, since the greeter user has no state of its own to read it from;
# the keyboard layouts it kept go into the compositor config the same way, so
# a password is typed on the layout a session starts on.
#
# The background is the Settings app's Lock Screen choice (lockscreen.json):
# an image of its own, none, or by default the desktop's wallpaper, read from
# the hyprpaper config the desktop starts from: the Settings app's saved one
# once something was picked there, .config/hypr/hyprpaper.conf before that.
# Re-run it after picking a new wallpaper, too. That page runs this through
# pkexec, hence PKEXEC_UID for whose home it is.
set -euo pipefail

# Physical: the Settings app reaches this through ~/.config/quickshell, a link.
repo=$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
dest=${1:-/etc/greetd}

owner=${SUDO_USER:-$(id -nu "${PKEXEC_UID:-$(id -u)}")}
owner_home=$(getent passwd "$owner" | cut -d: -f6)

# The same path .config/hypr/modules/startup.lua checks. sudo resets the
# environment, so this falls back to the owner's home rather than root's.
picked=${XDG_STATE_HOME:-$owner_home/.local/state}/quickshell/hyprpaper.conf
config=$repo/.config/hypr/hyprpaper.conf
[[ -r $picked ]] && config=$picked
wallpaper=$(sed -n 's/^[[:space:]]*path[[:space:]]*=[[:space:]]*//p' "$config" | tail -1)
wallpaper=${wallpaper/#\~/$owner_home}

look=${XDG_STATE_HOME:-$owner_home/.local/state}/quickshell/lockscreen.json
background=wallpaper
if [[ -r $look ]]; then
    background=$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1])).get("loginBackground", "wallpaper"))' "$look")
    [[ $background == image ]] && wallpaper=$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1])).get("loginImage", ""))' "$look")
fi
[[ $background == plain ]] && wallpaper=

# A fresh install has no wallpaper yet; the greeter shows its plain background
# until one is picked and this runs again.
if [[ -n $wallpaper && ! -r $wallpaper ]]; then
    echo "install-greeter: no wallpaper at '$wallpaper', installing without one" >&2
    wallpaper=
fi

echo "repo        $repo"
echo "destination $dest"
echo "wallpaper   ${wallpaper:-none}"

install -d -m 0755 "$dest" "$dest/quickshell" "$dest/quickshell/style"

install -m 0644 "$repo/etc/greetd/config.toml"  "$dest/config.toml"
install -m 0644 "$repo/etc/greetd/hyprland.lua" "$dest/hyprland.lua"
install -m 0644 "$repo/etc/greetd/monitors.lua" "$dest/monitors.lua"

# The same file .config/hypr/modules/monitors.lua loads after its own rules,
# applied the same way: last, so it wins.
kept=${XDG_STATE_HOME:-$owner_home/.local/state}/quickshell/monitors.lua
if [[ -r $kept ]]; then
    {
        printf '\n-- Kept by the Settings app, baked in by install-greeter.sh.\n'
        printf 'for _, rule in ipairs((function()\n'
        cat "$kept"
        printf 'end)()) do\n\thl.monitor(rule)\nend\n'
    } >> "$dest/monitors.lua"
    echo "monitors    + $kept"
fi

# The same file .config/hypr/modules/keybinds.lua applies to the session.
kept=${XDG_STATE_HOME:-$owner_home/.local/state}/quickshell/keyboard.lua
if [[ -r $kept ]]; then
    {
        printf '\n-- Kept by the Settings app, baked in by install-greeter.sh.\n'
        printf 'hl.config({ input = (function()\n'
        cat "$kept"
        printf 'end)() })\n'
    } >> "$dest/hyprland.lua"
    echo "keyboard    + $kept"
fi

install -m 0644 "$repo/etc/greetd/quickshell/qmldir" "$dest/quickshell/qmldir"
install -m 0644 "$repo"/etc/greetd/quickshell/*.qml "$dest/quickshell/"
install -m 0755 "$repo/etc/greetd/quickshell/greetd-auth.py" \
    "$dest/quickshell/greetd-auth.py"

install -m 0644 "$repo"/.config/quickshell/style/*.qml "$dest/quickshell/style/"
install -m 0644 "$repo/.config/quickshell/style/qmldir" "$dest/quickshell/style/qmldir"

if [[ -n $wallpaper ]]; then
    install -m 0644 "$wallpaper" "$dest/quickshell/wallpaper.jpg"
else
    rm -f "$dest/quickshell/wallpaper.jpg"
fi

# The Lock Screen choices, plus the image the background came from, by which
# that tab tells whether the login screen is up to date.
python3 - "$look" "$wallpaper" "$dest/quickshell/lockscreen.json" <<'PY'
import json, pathlib, sys
look, image, out = sys.argv[1:]
path = pathlib.Path(look)
settings = json.loads(path.read_text()) if path.is_file() else {}
settings["installedImage"] = image
pathlib.Path(out).write_text(json.dumps(settings, indent=4) + "\n")
PY

# The repo copies name /etc/greetd directly so they read as the real thing.
# Installing elsewhere (staging) rewrites those paths, so a staged tree is the
# same files rather than a separate test config.
if [[ $dest != /etc/greetd ]]; then
    sed -i "s#/etc/greetd#$dest#g" "$dest/config.toml" "$dest/hyprland.lua"
fi

# The greeter user is not in any group that would grant access by ownership, so
# everything has to be world readable and every directory world traversable.
chmod -R a+rX "$dest"

# The PAM stack adds the gnome-keyring lines SDDM used to provide, without which
# the login keyring never unlocks. It is the one file here that could lock you
# out, so: only on a real install, never when staging; keep a backup; and every
# rule it adds is `optional` with a `-` prefix so it cannot fail a login.
if [[ $dest == /etc/greetd ]]; then
    install -b -m 0644 "$repo/etc/pam.d/greetd" /etc/pam.d/greetd
    echo "pam         /etc/pam.d/greetd (previous kept as greetd~)"
else
    echo "pam         skipped (staging install, /etc/pam.d left alone)"
fi

echo
if [[ $dest == /etc/greetd ]]; then
    # No `systemctl restart greetd` here: the running session is on the VT
    # greetd draws on (config.toml), so a greeter started now would go there
    # too. greetd starts a fresh greeter whenever no session is running, which
    # reads these files anyway.
    echo "installed. the greeter picks it up the next time it starts: at logout or boot"
    echo "(first install: enable greetd as the README's \"Login screen\" says, then reboot;"
    echo "starting greetd from inside a session puts it on that session's VT)"
else
    echo "staged. drive it with:  GREETD_SOCK=<stub> qs -p $dest/quickshell/shell.qml"
fi
