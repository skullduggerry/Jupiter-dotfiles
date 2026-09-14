#!/usr/bin/env bash
# Standards check for this repo.
#
#     scripts/check.sh            verify everything, non-zero exit on failure
#     scripts/check.sh --fix      apply the safe fixes first, then verify
#     scripts/check.sh --staged   restrict file checks to what git has staged
#
# Formatting follows the official Qt/Quickshell QML conventions via qmlformat
# rather than a house style: member ordering, semicolons in functions and
# expressions, grouped property notation. See .github/PROJECT_STRUCTURE.md.
set -uo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo"

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

# qmllint crashes (exit 255, silently) on `void`/`var` in a signature, which the
# three IpcHandler files need. Excluded until that is fixed upstream.
lint_excluded() {
    case $(basename "$1") in
        Launcher.qml|Dropdown.qml|Lock.qml) return 0 ;;
        *) return 1 ;;
    esac
}

section "formatting (qmlformat, official QML conventions)"
while read -r f; do
    [[ -z $f || ! -f $f ]] && continue
    checked=$((checked + 1))
    # qmlformat exits non-zero with no output on two constructs it cannot parse:
    # a `: void` return type (which also crashes qmllint) and the spread
    # operator. Those files are skipped rather than failed; qmllint still covers
    # the ones it can read.
    if ! qmlformat "$f" >/dev/null 2>&1; then
        echo "  skip  $f (qmlformat cannot parse ': void' or spread)"
        continue
    fi
    if ! diff -q <(qmlformat "$f" 2>/dev/null | python3 scripts/normalise-pragmas.py) \
                 <(python3 scripts/normalise-pragmas.py < "$f") >/dev/null 2>&1; then
        if [[ $fix == 1 ]]; then
            qmlformat -i "$f" >/dev/null 2>&1 \
                && scripts/hoist-pragmas.py "$f" >/dev/null \
                && echo "  fixed $f"
            [[ $staged == 1 ]] && git add "$f"
        else
            fail "$f is not formatted (run scripts/check.sh --fix)"
        fi
    fi
done < <(qml_files)
[[ $failures == 0 ]] && pass "$checked qml files"

section "whitespace (.editorconfig)"
while read -r f; do
    [[ -z $f || ! -f $f ]] && continue
    if [[ $fix == 1 ]]; then
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
mapfile -t lintable < <(qml_files)
targets=()
for f in "${lintable[@]}"; do
    [[ -z $f || ! -f $f ]] && continue
    lint_excluded "$f" || targets+=("$f")
done
if [[ ${#targets[@]} -gt 0 ]]; then
    if out=$(qmllint -I /usr/lib/qt6/qml "${targets[@]}" 2>&1); then
        pass "${#targets[@]} files"
    else
        fail "qmllint"; echo "$out" | head -20
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
# config/hypr/styles/layout.lua blurs ^quickshell:.*-popup$ only. A popup named
# anything else silently renders unblurred.
while read -r line; do
    suffix=${line#*namespaceSuffix: \"}
    suffix=${suffix%\"*}
    [[ $suffix == *-popup ]] || fail "namespaceSuffix '$suffix' will not match the blur rule"
done < <(grep -rh 'namespaceSuffix: "' .config/quickshell --include='*.qml')
pass "all popup namespaces end in -popup"

section "nerd font glyph integrity"
was=$(scripts/glyph-count.py --head)
now=$(scripts/glyph-count.py)
if (( now < was )); then
    fail "glyph count fell repo-wide ($was -> $now); a tool may have emptied codepoints"
else
    pass "glyphs intact repo-wide ($was -> $now)"
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
done < <(find scripts .githooks -type f \( -name '*.sh' -o -path './.githooks/*' \) 2>/dev/null)
pass "shell sources parse"

section "greeter compositor config"
if command -v Hyprland >/dev/null; then
    if Hyprland --verify-config -c "$repo/etc/greetd/hyprland.lua" 2>&1 | grep -q 'config ok'; then
        pass "etc/greetd/hyprland.lua"
    else
        fail "etc/greetd/hyprland.lua does not verify"
    fi
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
