# Agent instructions

A desktop shell for Hyprland on Arch Linux, written in QML on Quickshell, plus
the Hyprland, wallust and app configs around it. Read
`.github/PROJECT_STRUCTURE.md` (the map, the conventions and the known
pitfalls) before changing the shell, and `.github/THEMING.md` before changing
colours outside it.

`.config/*` is symlinked into `~/.config/`, so this repo is the live session.
Quickshell and Hyprland reload as soon as a file they loaded changes.

## Sources of truth, in order

1. This repo's code and conventions.
2. The installed Quickshell's type information,
   `/usr/lib/qt6/qml/Quickshell/**/*.qmltypes` (`Quickshell.Widgets` is plain
   QML in the same folder). The online docs (quickshell.org/docs) may describe
   a newer version than the installed 0.3.1.
3. The Qt 6 QML docs, the Hyprland wiki (this config is Lua:
   `/usr/share/hypr/stubs/hl.meta.lua` lists the API), and the ArchWiki.

Don't copy APIs from other people's dotfiles, forum posts or older Quickshell
examples. Before you use a type, property, signal or dispatcher, find it in 1
or 2.

## Writing code

- Reuse the closest existing pattern. The bar and `panels/` are the reference
  implementation. Keep each change scoped to its task: no unrelated refactors,
  renames, reformatting or new dependencies. Explain any architectural change
  before you make it.
- Colours come from `style/Colors.qml`, derived from its palette. Sizes,
  spacing, radii, fonts and durations come from `style/Style.qml`. Reuse an
  existing token before adding a new one. Add new tokens to those files, named
  by role and never by widget.
- Naming: PascalCase files, camelCase ids and properties, typed properties
  rather than `var`. Import through `qs.<folder>` modules, with no unused
  imports.
- Prefer declarative bindings to imperative syncing, and never break a
  binding by assigning to its property. Keep state with whatever owns it, and
  derive values rather than duplicating them.
- Prefer Quickshell's reactive services (Hyprland, PipeWire, Networking,
  UPower, …) over processes, polling or repeated `hyprctl` calls. Run
  expensive work only while its result is on screen.
- Don't add fallbacks that hide a missing API. Handle state that is genuinely
  optional explicitly.
- Comments: a few lines explaining *why*, and only where the code doesn't make
  it obvious. Longer explanations go in `.github/`. Don't write human-facing
  docs (README) unless you're asked to.

## Done means

- `scripts/check.sh` passes (`--fix` formats first). Fix every failure you
  introduced, and name any that were already there.
- You have read the whole diff and checked the running shell's log after the
  reload (see "Validating" in PROJECT_STRUCTURE.md). Some failures only show
  up in the log.
- Your report covers what changed, why, how you verified it, and what you
  couldn't verify.
