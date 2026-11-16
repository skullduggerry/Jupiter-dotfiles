# Agent instructions

Hyprland desktop shell (QML, Quickshell 0.3.2) on Arch, plus Hyprland/wallust/app configs. Read `.github/PROJECT_STRUCTURE.md` before touching the shell, `.github/THEMING.md` before touching colours outside it. `.config/*` is symlinked into `~/.config/`: edits are live, Quickshell and Hyprland hot-reload.

## Sources of truth, in order

1. This repo.
2. `/usr/lib/qt6/qml/Quickshell/**/*.qmltypes` (online docs may be newer than 0.3.2).
3. Qt 6 QML docs, Hyprland wiki (config is Lua; API in `/usr/share/hypr/stubs/hl.meta.lua`), ArchWiki.

Verify every type/property/signal/dispatcher in 1 or 2. Never copy from other dotfiles, forums or old Quickshell examples.

## Code

- Follow the closest existing pattern (bar and `panels/` are the reference). Stay in scope: no unrelated refactors, renames, reformatting or dependencies. Explain architectural changes first.
- Colours from `style/Colors.qml`; sizes, spacing, radii, fonts, durations from `style/Style.qml`. Reuse tokens; new ones named by role, not widget.
- PascalCase files, camelCase ids/properties, typed properties (not `var`), relative imports (`import "../services"`), no unused imports.
- Declarative bindings; never assign over a binding. State lives with its owner; derive, don't duplicate.
- Quickshell services over processes/polling/`hyprctl`. Expensive work only while visible.
- No fallbacks hiding missing APIs; handle genuinely optional state explicitly.
- Comments: brief, *why* only. Long explanations go in `.github/`. No human docs unless asked.

## Done means

- `./check.sh` passes (`--fix` formats). Fix what you broke; name pre-existing failures.
- New behaviour has a test in `../Jupiter-testing` (see its `.github/`): scripts → `dotfiles/test_<name>.py`, QML → `dotfiles/qml/<Name>Test.qml`, login/lock/Nextcloud/external text → `dotfiles/security/`.
- Whole diff read; shell log checked after reload ("Validating" in PROJECT_STRUCTURE.md).
- Report: what changed, why, how verified, what wasn't.
