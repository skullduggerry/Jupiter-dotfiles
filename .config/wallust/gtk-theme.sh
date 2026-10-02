#!/usr/bin/env bash
# Name the Wallust GTK theme in gsettings, so GTK 3 apps that are running load
# it again: the file dialogs' portal (xdg-desktop-portal-gtk), which runs from
# login, among them. apply.sh runs this after rendering the theme, and the
# shell's services/app-tint.sh after writing a new tint into it.
#
#     gtk-theme.sh            name it, whatever was named before
#     gtk-theme.sh --reload   only if it is named already
#
# GTK 3 loads a theme again only when the name changes, and naming the one it
# has changes nothing (dconf drops the write). So the theme has a second name,
# Wallust-2, a link to the same folder, and each run names the one not in use.
set -uo pipefail

# Where wallust.toml renders it.
themes=$HOME/.local/share/themes
[[ -d $themes/Wallust ]] || exit 0
ln -sfn Wallust "$themes/Wallust-2"

current=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null) || exit 0
case $current in
    "'Wallust'") next=Wallust-2 ;;
    "'Wallust-2'") next=Wallust ;;
    *) [[ ${1:-} == --reload ]] && exit 0; next=Wallust ;;
esac
gsettings set org.gnome.desktop.interface gtk-theme "$next"
