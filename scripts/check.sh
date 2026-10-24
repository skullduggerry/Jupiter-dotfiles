#!/usr/bin/env bash
# The repo's checks: formatting, linters, the Hyprland configs and the tests.
#
#     scripts/check.sh            check everything, non-zero exit on failure
#     scripts/check.sh --fix      format, and apply the linters' safe fixes, first
#     scripts/check.sh --staged   only the files git has staged (pre-commit)
#
# Formatters: qmlformat (the official QML conventions), ruff, shfmt and
# stylua, set up in pyproject.toml and .editorconfig. Linters: qmllint,
# ruff, mypy, shellcheck and lua-language-server (.luarc.json, which knows
# Hyprland's hl API). Tests: Jupiter-testing's, next to this repo or at
# JUPITER_TESTING, whose scripts/test.sh runs this repo's suites under
# coverage: every helper script has to be run by one. See "Validating" in
# .github/PROJECT_STRUCTURE.md.
set -uo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd) || exit 2
cd "$repo" || exit 2
# The shell is Qt 6; /usr/bin/qmlformat and qmllint are Qt 5's (qt5-declarative)
# and misparse it.
PATH=/usr/lib/qt6/bin:$PATH

fix=0
staged=0
for arg in "$@"; do
    case $arg in
        --fix) fix=1 ;;
        --staged) staged=1 ;;
        *)
            echo "unknown option: $arg" >&2
            exit 2
            ;;
    esac
done

# Each tool, and the package it comes in.
declare -A packages=(
    ["/usr/lib/qt6/bin/qmlformat"]=qt6-declarative ["qs"]=quickshell ["Hyprland"]=hyprland
    ["ruff"]=ruff ["mypy"]=mypy ["shellcheck"]=shellcheck
    ["shfmt"]=shfmt ["luac"]=lua ["stylua"]=stylua ["lua-language-server"]=lua-language-server
    ["zsh"]=zsh
)
missing=()
for tool in "${!packages[@]}"; do
    command -v "$tool" >/dev/null || missing+=("${packages[$tool]}")
done
if ((${#missing[@]})); then
    echo "Some tools are missing. Install them with:" >&2
    echo "    sudo pacman -S --needed $(printf '%s\n' "${missing[@]}" | sort -u | xargs)" >&2
    exit 2
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

failures=0
fail() {
    echo "  FAIL  $*"
    failures=$((failures + 1))
}
ok() { echo "  ok    $*"; }
section() {
    echo
    echo "== $1"
    section_start=$failures
}
# Says ok if the section failed nothing.
passed() { ((failures == section_start)) && ok "$@"; }
# Fails with a tool's output, its first lines.
failed() {
    fail "$1"
    head -40 "$tmp/out" | sed 's/^/        /'
}

# The files matching git pathspecs, new ones included, or with --staged the
# staged ones. Links are checked as what they point to.
files() {
    if ((staged)); then
        git diff --cached --name-only --diff-filter=ACMR -- "$@"
    else
        git ls-files --cached --others --exclude-standard -- "$@"
    fi | while read -r f; do
        [[ -f $f && ! -L $f ]] && printf '%s\n' "$f"
    done
}
mapfile -t qml < <(files '*.qml')
mapfile -t python < <(files '*.py')
mapfile -t shell < <(files '*.sh' '.githooks/*' '.config/uwsm/env')
mapfile -t lua < <(files '*.lua' ':!.config/wallust/templates/*')

# With --staged, a file is only fixed and staged again when it has no unstaged
# changes, which `git add` would stage along with the fix.
fixable() { ((fix)) && { ((! staged)) || git diff --quiet -- "$1"; }; }
fixed() {
    echo "  fixed $1"
    ((staged)) && git add -- "$1"
}

# A file as its formatter would write it.
# shellcheck disable=SC2094 # its name only tells them which settings apply
formatted() {
    case $1 in
        *.qml) qmlformat "$1" ;;
        *.py) ruff format --quiet --stdin-filename "$1" - <"$1" ;;
        *.lua) stylua --stdin-filepath "$1" - <"$1" ;;
        *) shfmt "$1" ;;
    esac
}

section "formatting (qmlformat, ruff, shfmt, stylua)"
for f in "${qml[@]}" "${python[@]}" "${shell[@]}" "${lua[@]}"; do
    if ! out=$(formatted "$f" 2>"$tmp/out"); then
        failed "$f does not parse"
    elif [[ $out != "$(<"$f")" ]]; then
        if fixable "$f"; then
            printf '%s\n' "$out" >"$f" && fixed "$f"
        elif ((fix)); then
            fail "$f is not formatted and has unstaged changes: format it, then stage it"
        else
            fail "$f is not formatted (run scripts/check.sh --fix)"
        fi
    fi
done
passed "$((${#qml[@]} + ${#python[@]} + ${#shell[@]} + ${#lua[@]})) files"

section "whitespace (.editorconfig)"
# Trailing whitespace, except in Markdown, where two spaces end a line.
trailing() { [[ $1 != *.md ]] && grep -qP '[ \t]+$' "$1"; }
unended() { [[ -n $(tail -c1 "$1") ]]; }
while read -r f; do
    grep -Iq . "$f" || continue # binary
    if fixable "$f" && { trailing "$f" || unended "$f"; }; then
        trailing "$f" && sed -i 's/[ \t]*$//' "$f"
        unended "$f" && printf '\n' >>"$f"
        fixed "$f"
    fi
    trailing "$f" && fail "$f has trailing whitespace"
    unended "$f" && fail "$f has no final newline"
    [[ $f == *.qml ]] && grep -qP '\t' "$f" && fail "$f contains a tab"
done < <(files .)
passed "trailing whitespace, final newline, no tabs in QML"

section "qmllint"
# Against Quickshell's type information with its packaging slips fixed, and any
# warning fails. The greeter is linted as installed, beside a copy of style/.
# Paths are absolute: Qt 6.12's qmllint matches a file against its qmldir by
# absolute path, and warns about every singleton given a relative one.
lint=$tmp/lint
mkdir "$lint"
scripts/quickshell-types.py "$lint/types"
cp -r etc/greetd/quickshell "$lint/greeter"
cp -r .config/quickshell/style "$lint/greeter/style"
targets=()
for f in "${qml[@]}"; do
    if [[ $f == etc/greetd/quickshell/* ]]; then
        targets+=("$lint/greeter/${f#etc/greetd/quickshell/}")
    else
        targets+=("$repo/$f")
    fi
done
if ((${#targets[@]})); then
    if out=$(qmllint --bare -I "$lint/types" -I /usr/lib/qt6/qml --max-warnings 0 --unused-imports warning "${targets[@]}" 2>&1); then
        passed "${#targets[@]} files"
    else
        out=${out//$repo\//}
        echo "${out//$lint\/greeter/etc/greetd/quickshell}" >"$tmp/out"
        failed "qmllint"
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
passed "every qml declared in its qmldir"

section "popup namespaces (hyprland blur rule)"
# .config/hypr/styles/layout.lua blurs ^quickshell:.*-popup$ only. A popup named
# anything else silently renders unblurred.
while read -r line; do
    suffix=${line#*namespaceSuffix: \"}
    suffix=${suffix%\"*}
    [[ $suffix == *-popup ]] || fail "namespaceSuffix '$suffix' will not match the blur rule"
done < <(grep -rh 'namespaceSuffix: "' .config/quickshell --include='*.qml')
passed "all popup namespaces end in -popup"

section "pasted glyphs"
if pasted=$(scripts/pasted-glyphs.py); then
    passed "every glyph is a \\u{...} escape"
else
    fail "pasted glyphs, write them as \\u{...}: ${pasted//$'\n'/ }"
fi

section "icon family (lucide)"
# One icon set: every glyph is one of icons/Icons.qml's, in its font. A Nerd
# Font escape (U+F0000 and up) is the old set, and would draw in the text font.
if nerd=$(grep -rln '\\u{F[0-9A-Fa-f]\{4\}}' .config/quickshell etc/greetd --include='*.qml'); then
    fail "Nerd Font glyphs, use icons/Icons.qml: ${nerd//$'\n'/ }"
else
    passed "no Nerd Font glyphs"
fi

section "python (ruff, mypy)"
if ((${#python[@]})); then
    if ((fix)); then
        for f in "${python[@]}"; do
            fixable "$f" || continue
            before=$(<"$f")
            ruff check --fix --quiet "$f" >/dev/null
            [[ $(<"$f") != "$before" ]] && fixed "$f"
        done
    fi
    ruff check --quiet --output-format concise "${python[@]}" >"$tmp/out" 2>&1 || failed "ruff"
    mypy --no-error-summary "${python[@]}" >"$tmp/out" 2>&1 || failed "mypy"
fi
passed "${#python[@]} files"

section "lua (luac, lua-language-server)"
for f in "${lua[@]}"; do
    luac -p -- "$f" 2>"$tmp/out" || failed "$f does not parse"
done
if ((${#lua[@]})); then
    # The whole tree, as a module's callers matter to it.
    lua-language-server --check="$repo" --checklevel=Information --check_format=json \
        --logpath="$tmp/luals" >/dev/null 2>&1
    python3 - "$tmp/luals/check.json" "$repo" >"$tmp/out" <<'EOF' || failed "lua-language-server"
import json, sys, urllib.parse
problems = json.load(open(sys.argv[1]))
for uri, diagnostics in (problems or {}).items():
    path = urllib.parse.unquote(uri.removeprefix("file://")).removeprefix(sys.argv[2] + "/")
    for problem in diagnostics:
        line = problem["range"]["start"]["line"] + 1
        message = problem["message"].splitlines()[0]
        print(f"{path}:{line}: {message} [{problem['code']}]")
sys.exit(1 if problems else 0)
EOF
fi
passed "${#lua[@]} files"

section "shell (shellcheck, zsh -n)"
if ((${#shell[@]})); then
    shellcheck --format=gcc "${shell[@]}" >"$tmp/out" 2>&1 || failed "shellcheck"
fi
while read -r f; do
    zsh -n "$f" 2>"$tmp/out" || failed "$f does not parse"
done < <(files '.config/.zshrc')
passed "${#shell[@]} files and .zshrc"

section "json and toml"
mapfile -t data < <(files '*.json' '*.toml' ':!.config/wallust/templates/*')
python3 - "${data[@]}" >"$tmp/out" <<'EOF' || failed "json or toml that does not parse"
import json, sys, tomllib
broken = 0
for path in sys.argv[1:]:
    with open(path, "rb") as file:
        try:
            (tomllib.load if path.endswith(".toml") else json.load)(file)
        except ValueError as error:
            print(f"{path}: {error}")
            broken += 1
sys.exit(broken)
EOF
passed "${#data[@]} files"

section "hyprland configs"
# Hyprland's own parser, which also rejects unknown rule fields and wrong
# types; luac and lua-language-server only see the code.
for config in .config/hypr/hyprland.lua etc/greetd/hyprland.lua; do
    if Hyprland --verify-config -c "$repo/$config" 2>&1 | grep -q 'config ok'; then
        ok "$config"
    else
        fail "$config does not verify"
    fi
done

section "tests (Jupiter-testing)"
# A repo of their own, which reads this one where it is: the helpers against
# stand-in commands, the QML in Quickshell, the lock and login screens
# against stand-in PAM and greetd, under coverage, and every helper run by a
# test. It names any tool it needs that is missing.
testing=$(realpath -m "${JUPITER_TESTING:-$repo/../Jupiter-testing}")
if [[ ! -x $testing/scripts/test.sh ]]; then
    fail "no Jupiter-testing at $testing: clone it next to this repo, or set JUPITER_TESTING"
elif JUPITER_DOTFILES=$repo "$testing/scripts/test.sh" dotfiles >"$tmp/out" 2>&1; then
    passed "$(grep -c '^  ok' "$tmp/out") checks, $(grep -o 'python lines: [0-9]*%' "$tmp/out")"
else
    grep -A12 '^  FAIL' "$tmp/out" >"$tmp/fails" || tail -20 "$tmp/out" >"$tmp/fails"
    mv "$tmp/fails" "$tmp/out"
    failed "Jupiter-testing's scripts/test.sh dotfiles"
fi

echo
if ((failures)); then
    echo "FAILED: $failures problem(s)"
    exit 1
fi
echo "all checks passed"
