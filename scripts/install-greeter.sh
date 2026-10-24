#!/usr/bin/env bash
# Install the quickshell greeter where greetd's unprivileged `greeter` user can
# read it.
#
#     scripts/install-greeter.sh [--from REPO] [destination]
#
# The destination is /etc/greetd by default. What greetd and PAM run as root
# (this script, greetd's config.toml, the PAM stacks) comes from the tree this
# script is in: the repo when you run it with sudo yourself, root's copy in
# /usr/local/lib/jupiter/greeter (scripts/install-system.sh keeps it) when the
# Lock Screen tab runs it through pkexec, so that no file in a home decides
# what runs as root. Everything else, which only the unprivileged greeter user
# runs, comes from REPO, the owner's clone (by default that same tree), read
# as the owner.
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
# Re-run it after picking a new wallpaper, too. So does the desktop's theme,
# which the login screen follows unless that tab says otherwise: the palette
# wallust rendered, the Appearance choices (blur, tint, accent, font) and the
# theme's name go into quickshell/theme. That page runs root's copy through
# pkexec, hence PKEXEC_UID for whose home it is, and --from for their clone.
set -euo pipefail

# Physical: run from the repo, this is reached through ~/.config/quickshell,
# a link.
self=$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
repo=$self
dest=/etc/greetd
while (($#)); do
    case $1 in
        --from)
            repo=${2:?--from needs the repo}
            shift 2
            ;;
        *)
            dest=$1
            shift
            ;;
    esac
done

owner=${SUDO_USER:-$(id -nu "${PKEXEC_UID:-$(id -u)}")}
owner_home=$(getent passwd "$owner" | cut -d: -f6)

# Everything taken from the owner's home is read as the owner, never as root:
# the paths come from files they can write, and what is installed here is
# world readable.
owned() {
    if [[ $(id -u) == 0 ]]; then
        setpriv --reuid="$(id -u "$owner")" --regid="$(id -g "$owner")" --init-groups -- "$@"
    else
        "$@"
    fi
}

# A file of the owner's clone, read as the owner, installed world readable.
copy() {
    owned cat -- "$repo/$1" >"$2"
    chmod "${3:-0644}" "$2"
}

# The same path .config/hypr/modules/startup.lua checks. sudo resets the
# environment, so this falls back to the owner's home rather than root's.
picked=${XDG_STATE_HOME:-$owner_home/.local/state}/quickshell/hyprpaper.conf
config=$repo/.config/hypr/hyprpaper.conf
owned test -r "$picked" && config=$picked
wallpaper=$(owned cat -- "$config" | sed -n 's/^[[:space:]]*path[[:space:]]*=[[:space:]]*//p' | tail -1)
wallpaper=${wallpaper/#\~/$owner_home}

look=${XDG_STATE_HOME:-$owner_home/.local/state}/quickshell/lockscreen.json
settings=$(owned cat -- "$look" 2>/dev/null) || settings='{}'
setting() { python3 -c 'import json, sys; print(json.loads(sys.argv[1]).get(sys.argv[2], sys.argv[3]))' "$settings" "$@"; }
background=$(setting loginBackground wallpaper)
[[ $background == image ]] && wallpaper=$(setting loginImage "")
[[ $background == plain ]] && wallpaper=

# A fresh install has no wallpaper yet; the greeter shows its plain background
# until one is picked and this runs again.
if [[ -n $wallpaper ]] && ! owned test -r "$wallpaper"; then
    echo "install-greeter: no wallpaper at '$wallpaper', installing without one" >&2
    wallpaper=
elif [[ -n $wallpaper && $(owned file --brief --mime-type -- "$wallpaper") != image/* ]]; then
    echo "install-greeter: '$wallpaper' is not an image, installing without one" >&2
    wallpaper=
fi

echo "repo        $repo"
echo "trusted     $self"
echo "destination $dest"
echo "wallpaper   ${wallpaper:-none}"

install -d -m 0755 "$dest" "$dest/quickshell" "$dest/quickshell/style" "$dest/quickshell/theme"

# greetd reads it as root, and it names the user the greeter runs as.
install -m 0644 "$self/etc/greetd/config.toml" "$dest/config.toml"
copy etc/greetd/hyprland.lua "$dest/hyprland.lua"
copy etc/greetd/monitors.lua "$dest/monitors.lua"
copy etc/greetd/vconsole.lua "$dest/vconsole.lua"

# The same file .config/hypr/modules/monitors.lua loads after its own rules,
# applied the same way: last, so it wins.
kept=${XDG_STATE_HOME:-$owner_home/.local/state}/quickshell/monitors.lua
if lua=$(owned cat -- "$kept" 2>/dev/null); then
    {
        printf '\n-- Kept by the Settings app, baked in by install-greeter.sh.\n'
        printf 'for _, rule in ipairs((function()\n'
        printf '%s\n' "$lua"
        printf 'end)()) do\n\thl.monitor(rule)\nend\n'
    } >>"$dest/monitors.lua"
    echo "monitors    + $kept"
fi

# The same file .config/hypr/modules/keybinds.lua applies to the session.
kept=${XDG_STATE_HOME:-$owner_home/.local/state}/quickshell/keyboard.lua
if lua=$(owned cat -- "$kept" 2>/dev/null); then
    {
        printf '\n-- Kept by the Settings app, baked in by install-greeter.sh.\n'
        printf 'hl.config({ input = (function()\n'
        printf '%s\n' "$lua"
        printf 'end)() })\n'
    } >>"$dest/hyprland.lua"
    echo "keyboard    + $kept"
fi

copy etc/greetd/quickshell/qmldir "$dest/quickshell/qmldir"
for f in "$repo"/etc/greetd/quickshell/*.qml; do
    copy "etc/greetd/quickshell/${f##*/}" "$dest/quickshell/${f##*/}"
done
copy etc/greetd/quickshell/greeter-env.py "$dest/quickshell/greeter-env.py" 0755
# Before Quickshell's own greetd client, the greeter spoke greetd through this.
rm -f "$dest/quickshell/greetd-auth.py"

for f in "$repo"/.config/quickshell/style/*.qml; do
    copy ".config/quickshell/style/${f##*/}" "$dest/quickshell/style/${f##*/}"
done
copy .config/quickshell/style/qmldir "$dest/quickshell/style/qmldir"

# The desktop's theme, as style/Theme.qml reads it at home; one that is not
# there yet leaves the greeter on the shell's own colours.
state=${XDG_STATE_HOME:-$owner_home/.local/state}
cache=${XDG_CACHE_HOME:-$owner_home/.cache}
for pair in "palette.json:$cache/wallust/quickshell.json" \
    "appearance.json:$state/quickshell/appearance.json" \
    "theme:$state/wallust/theme"; do
    if owned test -r "${pair#*:}"; then
        owned cat -- "${pair#*:}" >"$dest/quickshell/theme/${pair%%:*}"
    else
        rm -f "$dest/quickshell/theme/${pair%%:*}"
    fi
done
theme=$(head -n 1 "$dest/quickshell/theme/theme" 2>/dev/null || true)
echo "theme       ${theme:-none}"

if [[ -n $wallpaper ]]; then
    owned cat -- "$wallpaper" >"$dest/quickshell/wallpaper.jpg"
    chmod 0644 "$dest/quickshell/wallpaper.jpg"
else
    rm -f "$dest/quickshell/wallpaper.jpg"
fi

# The Lock Screen choices, plus the image the background came from and the
# theme, by which that tab tells whether the login screen is up to date.
python3 - "$settings" "$wallpaper" "$theme" "$dest/quickshell" <<'PY'
import json, pathlib, sys
look, image, theme, out = sys.argv[1:]
settings = json.loads(look)
settings["installedImage"] = image
settings["installedTheme"] = theme
try:
    appearance = json.loads(pathlib.Path(out, "theme/appearance.json").read_text())
except (OSError, ValueError):
    appearance = {}
settings["installedAppearance"] = {
    key: appearance[key]
    for key in ("blur", "accent", "font", "lightTint", "darkTint")
    if key in appearance
}
pathlib.Path(out, "lockscreen.json").write_text(json.dumps(settings, indent=4) + "\n")
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
# the login keyring never unlocks; greetd-greeter, the greeter's own session, is
# greetd's stock stack without them. They are the files here that could lock
# you out, so: only on a real install, never when staging; keep a backup; and
# every rule added is `optional` with a `-` prefix so it cannot fail a login.
if [[ $dest == /etc/greetd ]]; then
    install -b -m 0644 "$self/etc/pam.d/greetd" /etc/pam.d/greetd
    install -b -m 0644 "$self/etc/pam.d/greetd-greeter" /etc/pam.d/greetd-greeter
    echo "pam         /etc/pam.d/greetd, greetd-greeter (previous ones kept as ~)"
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
