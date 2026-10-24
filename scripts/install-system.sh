#!/usr/bin/env bash
# Install what the dotfiles need outside the home, as root: the udev rules in
# etc/udev/rules.d (a drawing tablet's pad, which
# .config/quickshell/services/tablet.py reads) and the pacman hooks in
# etc/pacman.d/hooks with the scripts they run (uwsm-desktop-entries.py).
#
#     sudo scripts/install-system.sh [root]      default: /
#
# Jupiter-installer's phase 4 runs it, and it is safe to run again. Into
# another root (the tests) it installs the same files and leaves udev alone.
set -euo pipefail

repo=$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
root=${1:-/}
root=${root%/}

install -d -m 0755 "$root/etc/udev/rules.d" "$root/etc/pacman.d/hooks" "$root/usr/local/lib/jupiter"
install -m 0644 "$repo"/etc/udev/rules.d/*.rules "$root/etc/udev/rules.d/"
install -m 0755 "$repo/scripts/uwsm-desktop-entries.py" "$root/usr/local/lib/jupiter/"
install -m 0644 "$repo"/etc/pacman.d/hooks/*.hook "$root/etc/pacman.d/hooks/"
echo "installed   udev rules, pacman hooks"

# The hook sees what pacman changes from now on; this covers what is there.
ROOT=$root/ "$root/usr/local/lib/jupiter/uwsm-desktop-entries.py" </dev/null

if [[ -z $root ]]; then
    # Rules apply as a device is added, so the devices there now go through
    # them again: a connected tablet's pad becomes readable at once.
    udevadm control --reload
    udevadm trigger --subsystem-match=input --action=change
fi
