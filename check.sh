#!/usr/bin/env bash
# Lint and test the Jupiter repos: the repo you are in, unless you name
# others (./check.sh --help). Hands its arguments to Jupiter-testing's
# check.sh, found next to this repo or at JUPITER_TESTING, and cloned there
# from TESTING_REPO first if it is missing.
set -euo pipefail

dotfiles=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
testing=${JUPITER_TESTING:-$dotfiles/../Jupiter-testing}
if [[ -d $testing && ! -x $testing/check.sh ]]; then
    echo "check.sh: $testing has no check.sh: update it (git -C $testing pull)" >&2
    exit 2
elif [[ ! -d $testing ]]; then
    repo=${TESTING_REPO:-https://github.com/skullduggerry/Jupiter-testing.git}
    echo "==> Cloning Jupiter-testing into $testing, which runs the checks"
    git clone --quiet "$repo" "$testing" || {
        echo "check.sh: could not clone $repo: clone it yourself, or set JUPITER_TESTING" >&2
        exit 2
    }
fi
JUPITER_DOTFILES=$dotfiles exec "$testing/check.sh" "$@"
