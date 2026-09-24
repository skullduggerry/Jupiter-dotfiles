#!/usr/bin/env bash
# Apply a wallust theme to the shell and to every app template (kitty, nvim,
# kdeglobals, Kvantum). The shell's wallpaper app (config/quickshell/wallpaper/)
# runs this with a theme; modules/start.lua runs it bare at login.
#
#     apply.sh                                 the last theme again, the same way
#     apply.sh [--shell-only] THEME            a built-in (`wallust theme list`)
#                                              or colorschemes/THEME.json
#     apply.sh [--shell-only] --from IMAGE     a new colorscheme generated from
#                                              IMAGE, saved to colorschemes/
#
# --shell-only renders the shell's palette alone (shell.toml) and leaves the
# apps and the open terminals as they were. What was applied is recorded in
# $XDG_STATE_HOME/wallust/theme (name, then "all" or "shell-only"), which is
# where the shell reads the current theme from.
set -euo pipefail

# cargo installs wallust here, and nothing started by the compositor (the
# shell included) ever read .zshrc, which is the only place that adds it.
export PATH="$HOME/.cargo/bin:$PATH"

dir=$(dirname "$(readlink -f "$0")")
state=${XDG_STATE_HOME:-$HOME/.local/state}/wallust/theme

shell_only=0
if [[ $# -eq 0 && -z ${WALLUST_THEME:-} && -f $state ]]; then
    { read -r theme; read -r scope || true; } <"$state"
    [[ $scope == shell-only ]] && shell_only=1
else
    [[ ${1:-} == --shell-only ]] && { shell_only=1; shift; }
    if [[ ${1:-} == --from ]]; then
        image=$2
        wallust -q -s -T run --save-scheme "$image"
        # wallust names the scheme after the file, up to its first dot.
        name=$(basename "$image")
        theme=${name%%.*}
    else
        theme=${1:-${WALLUST_THEME:-Oxocarbon-Dark}}
    fi
fi

args=(-q)
((shell_only)) && args+=(-C "$dir/shell.toml" -s)

# `wallust cs` would take a built-in name too, but it tries colorschemes/ first
# and accepts any single file starting with the name, so Nord would pick up a
# Nord-Custom.json.
if [[ -f $dir/colorschemes/$theme.json ]]; then
    wallust "${args[@]}" cs "$theme.json"
else
    wallust "${args[@]}" theme "$theme"
fi

# Running Qt/KDE apps re-read kdeglobals on this broadcast (plasma-integration's
# platform theme listens for it). Kvantum draws most of Dolphin from its own
# theme, which only loads at startup; see .github/THEMING.md.
if ((!shell_only)); then
    dbus-send --session --type=signal /KGlobalSettings \
        org.kde.KGlobalSettings.notifyChange int32:0 int32:0 || true
fi

mkdir -p "$(dirname "$state")"
printf '%s\n%s\n' "$theme" "$( ((shell_only)) && echo shell-only || echo all)" >"$state"
