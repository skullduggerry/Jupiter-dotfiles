---
name: jupiter-dev
description: How to work on Jupiter-dotfiles (the Quickshell/QML desktop shell, Hyprland Lua config, wallust theming, login screen and helper scripts) the way this repo is written - where to read first, code and comment style, the house prose voice, commit messages, testing in Jupiter-testing and what "done" means. Use for any change to this repo, including docs in .github/ and commits.
---

# Working on Jupiter-dotfiles

The rules live in `.github/`. This skill says which to read when, and adds
what they leave unwritten: the voice, the commit format and the workflow.
Where this skill and `.github/` disagree, `.github/` wins.

## 1. Read before touching anything

| Changing | Read first |
| --- | --- |
| Anything | `.github/llm.md` (sources of truth, writing code, done means) |
| The shell, Hyprland, the login screen | `.github/PROJECT_STRUCTURE.md`: the folder's section, "Where things go", and every "Pitfalls" entry for the types you use |
| Colours outside the shell, wallust templates | `.github/THEMING.md` |
| Tests | `../Jupiter-testing/.github/llm.md` and its `PROJECT_STRUCTURE.md` |

Check every Quickshell type, property or signal against
`/usr/lib/qt6/qml/Quickshell/**/*.qmltypes` (installed 0.3.2), and Hyprland's
Lua API against `/usr/share/hypr/stubs/hl.meta.lua`. Never copy from other
dotfiles, forum posts or the online docs without checking them there.

`.config/*` is symlinked into `~/.config/`: **this repo is the live session**,
and saving a file reloads Quickshell or Hyprland. So:

- Don't open windows in the live session. Try risky changes in the hidden
  nested Hyprland (`special:nest`, "Validating" in PROJECT_STRUCTURE.md), or
  prototype QML in a copy, or offscreen (`QT_QPA_PLATFORM=offscreen`).
- After a save, read the running shell's log (`qs log -r …`, see "Validating")
  and count `Reloading configuration` lines; a failed reload keeps the old
  config running and only the log says so.
- Saving several Hyprland modules at once races the autoreload: run
  `hyprctl reload` after.
- Never kill a daemon by name (a nested session's share the names).

## 2. Writing code

Follow the closest existing file: the bar and `panels/` are the reference.
Keep a change to its task, with no unrelated renames, reformatting or
dependencies (packages go in Jupiter-installer's `packages/*.txt`). Explain
an architectural change before making it.

**QML** (details in PROJECT_STRUCTURE.md "Conventions")
- Colours from `style/Colors.qml` as formulas over `Colors.palette`; sizes,
  spacing, radii, fonts, durations from `style/Style.qml`. Reuse a token
  before adding one; name a new one by role, never by widget.
- PascalCase files, camelCase ids and properties, typed properties (not
  `var`), `required property` in delegates, `pragma ComponentBehavior: Bound`
  where a delegate reads an outer id, relative imports (`import "../services"`),
  no unused imports, a `qmldir` line for every type, written before its first use.
- Declarative bindings; never assign over a binding. Derive, don't duplicate.
  State lives in its owner; state shared by surfaces in `services/`.
- Respect the import DAG: `style/` and `services/` import nothing from the
  project, `panels/` only those two.
- Reactive Quickshell services over processes and polling; expensive work
  only while shown (`viewers`, `active`).
- Glyphs are Lucide, named in `icons/Icons.qml` as `"\u{E059}"` escapes, never pasted.
- Text from outside the shell sets `textFormat: Text.PlainText`.
- Functions with typed parameters that a binding reads declare a return type.

**Python helpers** (`services/*.py`, `scripts/*.py`)
- `#!/usr/bin/env python3`, then a module docstring that opens with one line
  saying what it is and for whom ("…, for services/Tablet.qml"), then usage
  lines and a sample of what it prints. Anything a test must replace comes
  from an environment variable named after the helper (`TABLET_ROOT`).
- ruff (79 columns) and mypy as in `pyproject.toml`; stdlib only unless a
  package is already used.
- Answer the shell with one JSON object whatever it is given; refuse bad
  input before writing anything.

**Shell** (`*.sh`)
- `#!/usr/bin/env bash`, a header comment saying what it does, who runs it
  and why, then `set -euo pipefail` (`-uo` where a failure must not stop it).
  4-space indent, `[[ ]]`, shfmt and shellcheck clean.

**Lua** (`.config/hypr/`)
- Tabs, up to 160 columns, a bind on one line (stylua, `.editorconfig`).
- A module opens with a comment saying what it holds, where its state is
  kept, and how the shell hands it over live (`hyprctl eval 'require(…).use({…})'`).
- `modules/startup.lua` stays plain data. Every bind carries a `description`.
- Where the stubs are narrower than Hyprland, a `---@diagnostic` comment says so.

**Comments**: a few lines on *why*, only where the code doesn't show it
("A floor, so the slider cannot black the screen."). Longer explanations,
and every new pitfall or rule, go into `.github/PROJECT_STRUCTURE.md` in its
section. Don't write README or wiki text unless asked.

## 3. The voice

Comments, docs and commit messages share one voice. Match it:

- Plain, concrete English about what a person sees or does: "a finger logs
  in", "the toasts give way to it", "the window stays up while…". Name the
  thing, not an abstraction ("the bar's lower edge", not "the UI boundary").
- British spelling: colour, centre, grey, behaviour, licence.
- Declarative and present tense in docs; give the reason with "so", "because",
  or a colon: "Hot reload needs a content change (`touch` does nothing)."
- Say what has already gone wrong when it explains a rule ("Nextcloud's
  `[org.freedesktop.CloudProviders]` stopped it starting at all").
- No "we", "simply", "just", marketing words, emoji, or hedging.
- Identifiers in backticks; files by repo path; Settings places as
  `Settings → Page → Tab`.

## 4. Testing

New behaviour gets a test in `../Jupiter-testing` (its own conventions apply):

| Changed | Test |
| --- | --- |
| A helper script `<name>.py`/`.sh` | `dotfiles/test_<name>.py`, running it against stand-in commands in a temporary home (the checks fail on a helper no test runs) |
| QML logic: a formula, parser, state change | `dotfiles/qml/<Name>Test.qml`, a `TestCase` with `test_*` functions |
| Logging in, locking, secrets, text from outside | `dotfiles/security/` |

Tests run the real code, replace only what reaches the system, and assert
what a person would notice. A test never changes this repo or anything
outside a temporary folder. Those test changes are commits in that repo.

## 5. Done means

1. `./check.sh` passes (`./check.sh --fix` formats first; `lint` or `test`
   alone; `test --security` for the security suites). Fix every failure you
   introduced and name any that were already there.
2. You read the whole diff (`git diff`), and the live log after the reload.
3. PROJECT_STRUCTURE.md is updated if a rule, pitfall, state file, entry point
   or installed version changed.
4. The report says what changed, why, how it was verified, and what wasn't.

## 6. Commits

Commit only when asked. One line, no body (apart from any attribution
trailer the session requires):

```
type[scope, scope]: what now happens, in the past tense, by/so/rather than how
```

- **type**: `feat` (something new a person can do or see), `fix` (something
  that was wrong now isn't), `docs` (`.github/`), `refactor`, `test`.
- **scope**: the top-level parts touched, lowercase, comma-space separated:
  `quickshell`, `hypr`, `etc`, `scripts`, `wallust`, `github`, or an app's
  config folder name (`claude`, `kitty`, `nvim`, `zsh`).
- **subject**: lowercase verb in the past tense ("kept", "let", "said",
  "added", "answered", "drew"), describing the effect a person notices, then
  the mechanism after "by", "so", "with" or "rather than". Join a second
  change with ";". No trailing full stop. Length is fine if every word earns it.

Examples from the history:

```
fix[quickshell]: kept every display flush against another and covering none, whether dropped, resized or turned off, so Hyprland can still find each one across a touching edge
fix[claude]: kept Claude Desktop's sign-in across restarts, by pointing Electron's secrets at gnome-keyring rather than basic_text
feat[quickshell]: let the calendar's week start on any day, following the locale until one is picked, and show the month or 1 to 3 weeks paged by as many, both kept in Settings → Calendar
docs[github]: brought the versions and pitfalls up to Hyprland 0.57.1 and Qt 6.12, and described the glass's muted text and rim
```

Work on `main` is normal here; the pre-commit hook formats staged files and
pre-push runs the checks (`../Jupiter-testing/scripts/install-hooks.sh` once).
