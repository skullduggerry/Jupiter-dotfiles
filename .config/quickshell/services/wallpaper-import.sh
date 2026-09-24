#!/usr/bin/env bash
# Ask for an image and copy it into the wallpaper library ($1), printing where
# it landed. Run by WallpaperService.importFile(); exits 1 when the dialog is
# cancelled. Quickshell has no file dialog of its own, hence zenity.
set -euo pipefail

library=$1
file=$(zenity --file-selection --title="Add wallpaper" \
    --file-filter="Images | *.jpg *.jpeg *.png *.webp *.bmp *.JPG *.JPEG *.PNG *.WEBP *.BMP")

mkdir -p "$library"
name=$(basename "$file")
dest=$library/$name
# The same image again is a no-op; a different one under a taken name gets a number.
n=1
while [[ -e $dest ]] && ! cmp -s "$file" "$dest"; do
    dest=$library/${name%.*}-$n.${name##*.}
    n=$((n + 1))
done
[[ -e $dest ]] || cp -- "$file" "$dest"
printf '%s\n' "$dest"
