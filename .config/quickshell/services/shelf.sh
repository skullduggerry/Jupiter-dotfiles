#!/usr/bin/env bash
# The shelf's file work, run by services/Shelf.qml:
#   shelf.sh paste <dir>         the clipboard into a new file (or the files it
#                                holds, copied), printing each name
#   shelf.sh note <dir> <text>   a note, as a new Markdown file named after its
#                                first line
#   shelf.sh copy <file>         a file back onto the clipboard
# Exits 1 with nothing to paste and 3 for a password: the folder is synced.
set -euo pipefail

# A free path in $1 for the name $2 and extension $3 (or none), numbered when
# taken.
fresh() {
    local suffix=${3:+.$3} n=1
    local dest=$1/$2$suffix
    while [[ -e $dest ]]; do
        dest=$1/$2-$n$suffix
        n=$((n + 1))
    done
    printf '%s\n' "$dest"
}

# What the command after $1 prints, kept at $1 if it succeeds with something.
# Written under a hidden name first, which the Nextcloud client does not sync,
# so nothing half-written is uploaded or listed.
store() {
    local dest=$1 part
    shift
    part=$(dirname -- "$dest")/.$(basename -- "$dest").part
    if "$@" >"$part" && [[ -s $part ]]; then
        mv -- "$part" "$dest"
        basename -- "$dest"
    else
        rm -f -- "$part"
        return 1
    fi
}

paste() {
    local dir=$1 types type stamp uri path name ext copied=0
    types=$(wl-paste --list-types 2>/dev/null) || exit 1
    # KeePassXC marks its copies; cliphist skips them for the same reason.
    grep -qx 'x-kde-passwordManagerHint' <<<"$types" && exit 3
    mkdir -p -- "$dir"
    stamp=$(date +%Y-%m-%d_%H-%M-%S)

    # Files copied in a file manager: the files themselves.
    if grep -qx 'text/uri-list' <<<"$types"; then
        while IFS= read -r uri; do
            uri=${uri%$'\r'}
            [[ $uri == file://* ]] || continue
            path=${uri#file://}
            path=$(printf '%b' "${path//%/\\x}")
            [[ -f $path ]] || continue
            # Not hidden: the client would not sync it, nor the shelf list it.
            name=$(basename -- "$path")
            name=${name#"${name%%[!.]*}"}
            [[ -n $name ]] || name=$stamp
            if [[ $name == ?*.* ]]; then
                store "$(fresh "$dir" "${name%.*}" "${name##*.}")" cat -- "$path"
            else
                store "$(fresh "$dir" "$name" "")" cat -- "$path"
            fi
            copied=1
        done < <(wl-paste --no-newline --type text/uri-list)
        ((copied)) && return
    fi

    type=$(grep -m1 -x 'image/png' <<<"$types" || grep -m1 '^image/' <<<"$types" || true)
    if [[ -n $type ]]; then
        ext=${type#image/}
        ext=${ext%%+*}
        [[ $ext == jpeg ]] && ext=jpg
        store "$(fresh "$dir" "$stamp" "$ext")" wl-paste --no-newline --type "$type"
        return
    fi

    grep -q -e '^text/' -e '^UTF8_STRING$' -e '^STRING$' <<<"$types" || exit 1
    store "$(fresh "$dir" "$stamp" txt)" wl-paste --no-newline --type text
}

note() {
    local dir=$1 text=$2 name
    [[ -n ${text//[[:space:]]/} ]] || exit 1
    # The first line as the name, as the Nextcloud Notes app does, without
    # what a file name cannot hold and without a leading dot.
    name=$(head -n1 <<<"$text" | tr -d '/\\:*?"<>|' | tr -s '[:space:]' ' ' | cut -c1-40)
    name=${name#"${name%%[![:space:].]*}"}
    name=${name%"${name##*[![:space:]]}"}
    [[ -n $name ]] || name=$(date +%Y-%m-%d_%H-%M-%S)
    mkdir -p -- "$dir"
    store "$(fresh "$dir" "$name" md)" printf '%s\n' "$text"
}

# Text and images as themselves; anything else as the file, for a file
# manager or an upload field to take.
copy() {
    local file=$1 mime
    mime=$(file --brief --mime-type -- "$file")
    case $mime in
        text/*) wl-copy <"$file" ;;
        image/*) wl-copy --type "$mime" <"$file" ;;
        *) python3 -c 'import pathlib, sys; print(pathlib.Path(sys.argv[1]).as_uri())' "$file" | wl-copy --type text/uri-list ;;
    esac
}

case ${1-} in
    paste | note | copy) "$@" ;;
    *) exit 2 ;;
esac
