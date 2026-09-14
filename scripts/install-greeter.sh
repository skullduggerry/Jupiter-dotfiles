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
# style/ is copied rather than duplicated in the repo, so config/quickshell/
# stays the single source of truth for the design system. Re-run this after
# changing any colour or dimension, or the greeter keeps the old ones.
#
# The wallpaper path is read from config/hypr/hyprpaper.conf so the greeter
# always shows the same image as the desktop.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
dest=${1:-/etc/greetd}

owner_home=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)

wallpaper=$(sed -n 's/^[[:space:]]*path[[:space:]]*=[[:space:]]*//p' \
    "$repo/.config/hypr/hyprpaper.conf" | head -1)
wallpaper=${wallpaper/#\~/$owner_home}

if [[ ! -r $wallpaper ]]; then
    echo "install-greeter: cannot read wallpaper '$wallpaper'" >&2
    exit 1
fi

echo "repo        $repo"
echo "destination $dest"
echo "wallpaper   $wallpaper"

install -d -m 0755 "$dest" "$dest/quickshell" "$dest/quickshell/style"

install -m 0644 "$repo/etc/greetd/config.toml"  "$dest/config.toml"
install -m 0644 "$repo/etc/greetd/hyprland.lua" "$dest/hyprland.lua"

install -m 0644 "$repo/etc/greetd/quickshell/qmldir" "$dest/quickshell/qmldir"
install -m 0644 "$repo"/etc/greetd/quickshell/*.qml "$dest/quickshell/"
install -m 0755 "$repo/etc/greetd/quickshell/greetd-auth.py" \
    "$dest/quickshell/greetd-auth.py"

install -m 0644 "$repo"/.config/quickshell/style/*.qml "$dest/quickshell/style/"
install -m 0644 "$repo/.config/quickshell/style/qmldir" "$dest/quickshell/style/qmldir"

install -m 0644 "$wallpaper" "$dest/quickshell/wallpaper.jpg"

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
    echo "installed. apply with:  sudo systemctl restart greetd"
    echo "(restarting only replaces the greeter; it does not touch your session)"
else
    echo "staged. drive it with:  GREETD_SOCK=<stub> qs -p $dest/quickshell/shell.qml"
fi
