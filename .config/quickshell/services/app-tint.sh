#!/usr/bin/env bash
# Set the apps' glass to opacity $1, the shell's. It is recorded in
# $XDG_STATE_HOME/quickshell/tint.conf, in kitty's syntax:
# .config/kitty/kitty.conf includes it for the windows kitty opens next, and
# .config/wallust/appearance.py reads it when a theme is applied. Kvantum's SVG
# gets it where windows and dialogs are drawn, for the Qt apps that start next,
# and the open kittys are sent it over their sockets
# ($XDG_RUNTIME_DIR/kitty-<pid>), which take no other command without a
# password. The GTK themes get it too, and the GTK 3 apps that are running load
# theirs again. Run by AppTint.
set -uo pipefail

state=${XDG_STATE_HOME:-$HOME/.local/state}/quickshell
mkdir -p "$state"
# Whole or not at all: appearance.py may read it at any moment.
printf '# Written by the shell (.config/quickshell/services/AppTint.qml).\nbackground_opacity %s\n' "$1" >"$state/tint.conf.new"
mv "$state/tint.conf.new" "$state/tint.conf"

# The elements scripts/kvantum-template.py marks class="tint", one per line.
svg=$HOME/.config/Kvantum/Wallust/Wallust.svg
[[ -f $svg ]] && sed -i -E "/class=\"tint\"/ s/(opacity:)[0-9.]+/\1$1/" "$svg"

# The lines .config/wallust/templates/gtk.css marks glass, in the GTK 3 theme
# and in every GTK 4 app's stylesheet, as wallust.toml renders them.
for css in "$HOME/.local/share/themes/Wallust/gtk-3.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"; do
    [[ -f $css ]] && sed -i -E "/\/\* glass \*\// s/(alpha\(#[0-9A-Fa-f]{6}, )[0-9.]+\)/\1$1)/" "$css"
done
"$(dirname "$(readlink -f "$0")")/../../wallust/gtk-theme.sh" --reload

for socket in "$XDG_RUNTIME_DIR"/kitty-*; do
    # A kitty that crashed leaves its socket behind.
    [[ -S $socket ]] && kitten @ --to "unix:$socket" set-background-opacity --all "$1" >/dev/null 2>&1
done
exit 0
