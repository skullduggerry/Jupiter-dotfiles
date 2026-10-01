#!/usr/bin/env bash
# Set the apps' glass to opacity $1, the shell's. It is recorded in
# $XDG_STATE_HOME/quickshell/tint.conf, in kitty's syntax: config/kitty/kitty.conf
# includes it for the windows kitty opens next, and config/wallust/appearance.py
# reads it when a theme is applied. Kvantum's SVG gets it where windows and
# dialogs are drawn, for the Qt apps that start next, and the open kittys are
# sent it over their sockets ($XDG_RUNTIME_DIR/kitty-<pid>), which take no
# other command without a password. Run by AppTint.
set -uo pipefail

state=${XDG_STATE_HOME:-$HOME/.local/state}/quickshell
mkdir -p "$state"
# Whole or not at all: appearance.py may read it at any moment.
printf '# Written by the shell (config/quickshell/services/AppTint.qml).\nbackground_opacity %s\n' "$1" >"$state/tint.conf.new"
mv "$state/tint.conf.new" "$state/tint.conf"

# The elements scripts/kvantum-template.py marks class="tint", one per line.
svg=$HOME/.config/Kvantum/Wallust/Wallust.svg
[[ -f $svg ]] && sed -i -E "/class=\"tint\"/ s/(opacity:)[0-9.]+/\1$1/" "$svg"

for socket in "$XDG_RUNTIME_DIR"/kitty-*; do
    # A kitty that crashed leaves its socket behind.
    [[ -S $socket ]] && kitten @ --to "unix:$socket" set-background-opacity --all "$1" >/dev/null 2>&1
done
exit 0
