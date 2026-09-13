#!/usr/bin/env bash
# Regenerate every wallust template (kitty, nvim, kdeglobals, Kvantum).
#
# modules/start.lua runs this at login.
#
# The palette is a fixed built-in theme, not derived from the wallpaper:
# `wallust run <image>` on the current wallpaper produces a washed-out
# monochrome blue, which is why this is a theme and not an image.
set -euo pipefail

theme="${WALLUST_THEME:-Oxocarbon-Dark}"

exec wallust theme "$theme" "$@"
