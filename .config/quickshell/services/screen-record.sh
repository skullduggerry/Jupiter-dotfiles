#!/usr/bin/env bash
# Record the monitor named $1 into a new file, printing its path first, until
# SIGINT, which wf-recorder takes as "finish the file". Run by
# QuickToggles.setRecording(); dies with the shell (setpriv's parent-death
# signal), since a recording nobody can stop would run until the disk is full.
set -euo pipefail

output=$1
videos=$(xdg-user-dir VIDEOS 2>/dev/null || true)
# xdg-user-dirs points a folder it was told not to have at $HOME itself.
[[ -z $videos || ${videos%/} == "${HOME%/}" ]] && videos=$HOME/Videos
dir=$videos/Recordings
mkdir -p "$dir"
file=$dir/$(date +%Y-%m-%d_%H-%M-%S).mp4
printf '%s\n' "$file"
exec setpriv --pdeathsig INT wf-recorder -o "$output" -f "$file"
