#!/usr/bin/env bash
# Apply a wallust theme to the shell and to every app template (kitty, nvim,
# kdeglobals, Kvantum, qt6ct, GTK), then tell running apps; on NixOS, switch
# the apps Stylix themes to the theme's pre-built colours. The shell runs
# this with a theme (.config/quickshell/style/Theme.qml, for the Settings app's
# Themes tab); modules/start.lua runs it bare at login.
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
default=${WALLUST_THEME:-Oxocarbon-Dark}

shell_only=0
if [[ $# -eq 0 && -z ${WALLUST_THEME:-} && -f $state ]]; then
    {
        read -r theme || true
        read -r scope || true
    } <"$state"
    # An empty file, as a cut-off write leaves, would stop every login's run.
    theme=${theme:-$default}
    [[ $scope == shell-only ]] && shell_only=1
else
    [[ ${1:-} == --shell-only ]] && {
        shell_only=1
        shift
    }
    if [[ ${1:-} == --from ]]; then
        image=$2
        wallust -q -s -T run --save-scheme "$image"
        # wallust names the scheme after the file, up to its first dot.
        name=$(basename "$image")
        theme=${name%%.*}
    else
        theme=${1:-$default}
    fi
fi

# wallust saves the escape sequences for new terminals here, but does not
# create the folder, which a fresh home does not have yet.
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/wallust"

args=(-q)
if ((shell_only)); then
    args+=(-C "$dir/shell.toml" -s)
else
    # The Settings app's accent and font reach the app templates as
    # appearance.jinja: wallust renders from a copy of this folder in which
    # that file is written from the shell's state, not the committed defaults.
    config=$(mktemp -d)
    trap 'rm -rf "$config"' EXIT
    mkdir "$config/templates"
    ln -s "$dir"/templates/* "$config/templates/"
    rm "$config/templates/appearance.jinja"
    python3 "$dir/appearance.py" "${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/appearance.json" \
        >"$config/templates/appearance.jinja"
    ln -s "$dir/colorschemes" "$dir/wallust.toml" "$config/"
    args+=(-d "$config")
fi

# `wallust cs` would take a built-in name too, but it tries colorschemes/ first
# and accepts any single file starting with the name, so Nord would pick up a
# Nord-Custom.json.
if [[ -f $dir/colorschemes/$theme.json ]]; then
    wallust "${args[@]}" cs "$theme.json"
else
    wallust "${args[@]}" theme "$theme"
fi

if ((! shell_only)); then
    # Merged rather than rendered over: KDE apps keep settings of their own in
    # kdeglobals.
    python3 "$dir/kdeglobals.py" \
        "$HOME/.cache/wallust/kdeglobals" "${XDG_CONFIG_HOME:-$HOME/.config}/kdeglobals"

    # Dark or light, for everything that asks the desktop portal: GTK 4,
    # Electron, browsers, and Qt apps with a theme of their own on "automatic".
    gsettings set org.gnome.desktop.interface color-scheme "$(<"$HOME/.cache/wallust/color-scheme")" || true

    # The Wallust GTK theme, named so that running GTK 3 apps load it again.
    "$dir/gtk-theme.sh" || true

    # On NixOS, the apps Stylix themes (Jupiter-installer's nixos/theme.nix):
    # its home-manager generation has a specialisation for each theme in
    # base16/, and is the default theme's itself. Activated only when another
    # is active, as at the first login after a boot, which activates the
    # plain one. JUPITER_HOME_GENERATION is the tests' stand-in.
    home=${JUPITER_HOME_GENERATION:-/etc/jupiter/home}
    if [[ -x $home/activate ]]; then
        generation=$home
        [[ -x $home/specialisation/$theme/activate ]] && generation=$home/specialisation/$theme
        current=${XDG_STATE_HOME:-$HOME/.local/state}/home-manager/gcroots/current-home
        if [[ $(readlink -f "$generation") != "$(readlink -f "$current")" ]]; then
            # A config the app wrote itself is kept beside it, as at boot.
            HOME_MANAGER_BACKUP_EXT=before-stylix "$generation/activate" >/dev/null ||
                echo "apply.sh: home-manager's activation failed: btop, mpv and Zed keep the theme before" >&2
        fi
    fi
fi

mkdir -p "$(dirname "$state")"
# Whole or not at all: the next login reads it.
printf '%s\n%s\n' "$theme" "$( ((shell_only)) && echo shell-only || echo all)" >"$state.new"
mv "$state.new" "$state"
