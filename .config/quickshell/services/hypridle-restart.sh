#!/usr/bin/env bash
# Start hypridle again on the config $1, as it reads its config only at start.
# Run by Idle after a pick. Only this session's goes, the one with this
# Hyprland's instance signature: another session's, or a nested Hyprland's,
# keeps running.
set -uo pipefail

for pid in $(pgrep -u "$(id -u)" -x hypridle); do
    grep -qxz "HYPRLAND_INSTANCE_SIGNATURE=$HYPRLAND_INSTANCE_SIGNATURE" "/proc/$pid/environ" 2>/dev/null && kill "$pid"
done
exec hypridle -c "$1"
