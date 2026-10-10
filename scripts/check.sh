#!/usr/bin/env bash
# Standards check for this repo.
#
#     scripts/check.sh            verify everything, non-zero exit on failure
#     scripts/check.sh --fix      apply the safe fixes first, then verify
#     scripts/check.sh --staged   restrict file checks to what git has staged
#
# Formatting is qmlformat's, i.e. the official Qt QML conventions rather than a
# house style. See .github/PROJECT_STRUCTURE.md.
set -uo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo"
# The shell is Qt 6; /usr/bin/qmlformat and qmllint are Qt 5's (qt5-declarative)
# and misparse it.
PATH=/usr/lib/qt6/bin:$PATH

fix=0
staged=0
for arg in "$@"; do
    case $arg in
        --fix) fix=1 ;;
        --staged) staged=1 ;;
        *) echo "unknown option: $arg" >&2; exit 2 ;;
    esac
done

failures=0
checked=0

fail() { echo "  FAIL  $*"; failures=$((failures + 1)); }
pass() { echo "  ok    $*"; }
section() { echo; echo "== $1"; }

qml_files() {
    if [[ $staged == 1 ]]; then
        git diff --cached --name-only --diff-filter=ACM -- '*.qml'
    else
        find .config/quickshell etc/greetd -name '*.qml' 2>/dev/null
    fi
}

# With --staged, a file is only fixed and staged again when it has no unstaged
# changes, which `git add` would stage along with the fix.
fixable() { [[ $fix == 1 ]] && { [[ $staged == 0 ]] || git diff --quiet -- "$1"; }; }

section "formatting (qmlformat, official QML conventions)"
while read -r f; do
    [[ -z $f || ! -f $f ]] && continue
    checked=$((checked + 1))
    if ! formatted=$(qmlformat "$f" 2>/dev/null); then
        fail "$f does not parse (qmllint below says where)"
    elif ! diff -q <(echo "$formatted") "$f" >/dev/null; then
        if fixable "$f"; then
            qmlformat -i "$f" && echo "  fixed $f"
            [[ $staged == 1 ]] && git add "$f"
        elif [[ $fix == 1 ]]; then
            fail "$f is not formatted and has unstaged changes: format it, then stage it"
        else
            fail "$f is not formatted (run scripts/check.sh --fix)"
        fi
    fi
done < <(qml_files)
[[ $failures == 0 ]] && pass "$checked qml files"

section "whitespace (.editorconfig)"
while read -r f; do
    [[ -z $f || ! -f $f ]] && continue
    if fixable "$f"; then
        sed -i 's/[[:space:]]*$//' "$f"
        [[ -n $(tail -c1 "$f") ]] && printf '\n' >> "$f"
        [[ $staged == 1 ]] && git add "$f"
    else
        grep -qP '[ \t]+$' "$f" && fail "$f has trailing whitespace"
        [[ -n $(tail -c1 "$f") ]] && fail "$f has no final newline"
        grep -qP '\t' "$f" && fail "$f contains a tab"
    fi
done < <(qml_files)
pass "trailing whitespace, final newline, no tabs"

section "qmllint"
# Against Quickshell's type information with its packaging slips fixed, and any
# warning fails. The greeter is linted as installed, beside a copy of style/.
# Paths are absolute: Qt 6.12's qmllint matches a file against its qmldir by
# absolute path, and warns about every singleton given a relative one.
lint=$(mktemp -d)
trap 'rm -rf "$lint"' EXIT
scripts/quickshell-types.py "$lint/types"
cp -r etc/greetd/quickshell "$lint/greeter"
cp -r .config/quickshell/style "$lint/greeter/style"
targets=()
while read -r f; do
    [[ -n $f && -f $f ]] || continue
    if [[ $f == etc/greetd/quickshell/* ]]; then
        targets+=("$lint/greeter/${f#etc/greetd/quickshell/}")
    else
        targets+=("$repo/$f")
    fi
done < <(qml_files)
if [[ ${#targets[@]} -gt 0 ]]; then
    if out=$(qmllint --bare -I "$lint/types" -I /usr/lib/qt6/qml --max-warnings 0 --unused-imports warning "${targets[@]}" 2>&1); then
        pass "${#targets[@]} files"
    else
        out=${out//$repo\//}
        fail "qmllint"; echo "${out//$lint\/greeter/etc/greetd/quickshell}" | head -40
    fi
fi

section "qmldir completeness"
while read -r dir; do
    for f in "$dir"/*.qml; do
        [[ -e $f ]] || continue
        name=$(basename "$f" .qml)
        [[ $name == shell ]] && continue
        grep -q "[[:space:]]$name\.qml\$" "$dir/qmldir" || fail "$name.qml missing from $dir/qmldir"
    done
done < <(find .config/quickshell etc/greetd -name qmldir -printf '%h\n' 2>/dev/null)
pass "every qml declared in its qmldir"

section "popup namespaces (hyprland blur rule)"
# .config/hypr/styles/layout.lua blurs ^quickshell:.*-popup$ only. A popup named
# anything else silently renders unblurred.
while read -r line; do
    suffix=${line#*namespaceSuffix: \"}
    suffix=${suffix%\"*}
    [[ $suffix == *-popup ]] || fail "namespaceSuffix '$suffix' will not match the blur rule"
done < <(grep -rh 'namespaceSuffix: "' .config/quickshell --include='*.qml')
pass "all popup namespaces end in -popup"

section "pasted glyphs"
if pasted=$(scripts/pasted-glyphs.py); then
    pass "every glyph is a \\u{...} escape"
else
    fail "pasted glyphs, write them as \\u{...}: $(echo $pasted)"
fi

section "icon family (lucide)"
# One icon set: every glyph is one of icons/Icons.qml's, in its font. A Nerd
# Font escape (U+F0000 and up) is the old set, and would draw in the text font.
if nerd=$(grep -rln '\\u{F[0-9A-Fa-f]\{4\}}' .config/quickshell etc/greetd --include='*.qml'); then
    fail "Nerd Font glyphs, use icons/Icons.qml: $(echo $nerd)"
else
    pass "no Nerd Font glyphs"
fi

section "python"
while read -r f; do
    python3 -m py_compile "$f" 2>/dev/null || fail "$f does not compile"
done < <(find . -name '*.py' -not -path './.git/*' -not -path '*/__pycache__/*')
pass "python sources compile"

section "lua"
while read -r f; do
    luac -p "$f" 2>/dev/null || fail "$f does not parse"
done < <(find .config/hypr etc -name '*.lua' 2>/dev/null)
pass "lua sources parse"

section "shell"
while read -r f; do
    bash -n "$f" 2>/dev/null || fail "$f does not parse"
done < <(find scripts .githooks .config -type f \( -name '*.sh' -o -path './.githooks/*' \) 2>/dev/null)
pass "shell sources parse"

section "hyprland configs"
# Hyprland's own parser, which also rejects unknown rule fields and wrong
# types; luac above only sees the syntax.
if command -v Hyprland >/dev/null; then
    for config in .config/hypr/hyprland.lua etc/greetd/hyprland.lua; do
        if Hyprland --verify-config -c "$repo/$config" 2>&1 | grep -q 'config ok'; then
            pass "$config"
        else
            fail "$config does not verify"
        fi
    done
fi

section "tests"
for t in tests/*-test.py; do
    [[ -e $t ]] || continue
    if out=$(python3 "$t" 2>&1); then
        pass "$(basename "$t")"
    else
        fail "$(basename "$t")"; echo "$out" | tail -15
    fi
done

echo
if [[ $failures -gt 0 ]]; then
    echo "FAILED: $failures problem(s)"
    exit 1
fi
echo "all checks passed"
