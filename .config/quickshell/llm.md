Quickshell Project — Agent Instructions
1. Project Context

This project is a custom desktop shell built with QML and Quickshell, intended to run alongside Hyprland on Arch Linux.

The existing implementation is the primary source of truth for project architecture, visual language, component structure, and established implementation patterns.

When implementing or modifying functionality, preserve the existing architecture unless there is a clear technical reason to change it.

2. Documentation Sources

Use authoritative documentation to verify APIs, properties, signals, types, and implementation details.

Required sources
Quickshell: version 0.3.0
https://quickshell.org/docs/v0.3.0/
https://quickshell.org/docs/v0.3.0/types/
Hyprland: official documentation/wiki
Arch Linux: official ArchWiki
Qt/QML: official Qt documentation where Quickshell documentation does not sufficiently describe the underlying Qt/QML behavior
Documentation priority

When determining how something should be implemented, use this order:

Existing project implementation and established project conventions
Quickshell 0.3.0 documentation
Official Qt/QML documentation
Official Hyprland documentation
ArchWiki
Other sources only when the above do not provide sufficient information

Do not treat random dotfiles, GitHub repositories, forum posts, or outdated Quickshell examples as authoritative.

If documentation differs between versions, prefer documentation matching the project's actual installed version.

3. Inspect Before Implementing

Before changing code:

Inspect the repository structure.
Locate and read the existing bar implementation.
Locate Colors.qml, Style.qml, and other shared components.
Identify existing layout, spacing, sizing, radius, typography, and color conventions.
Identify how Hyprland state is currently accessed.
Identify existing patterns for Quickshell windows, panels, widgets, models, signals, and bindings.
Identify existing validation/build/lint commands.
Reuse an existing pattern whenever one already exists.

Do not immediately create a new component architecture without first understanding the existing one.

When adding a new UI element, the existing bar should be treated as the primary reference implementation.

4. QML and Quickshell Requirements

All implementation must use QML/Quickshell unless the task explicitly requires another technology.

Follow Quickshell's documented QML conventions.

Naming

Follow official QML/Quickshell naming conventions:

QML type files use PascalCase, e.g. WorkspaceWidget.qml.
QML object ids use lowercase/camelCase, e.g. workspaceWidget.
Properties use lower camel case.
Use descriptive names that communicate purpose.
Avoid abbreviations unless they are already established by the project or API.
Do not use uppercase names for properties or ids.
Prefer explicit property types instead of unnecessary var properties.

Example:

Item {
    id: workspaceWidget

    property int workspaceCount: 5
    property string workspaceName: ""
}


Use typed properties whenever practical. Avoid var when a concrete QML type can be used.

5. Imports

Use the import style recommended by Quickshell.

Prefer Quickshell module imports such as:

import qs.components
import qs.services


over relative imports when the corresponding project module structure supports them.

Keep imports minimal and remove unused imports.

Do not invent import paths. Verify that the imported module/type actually exists.

6. Design System
Colors

All layout/UI colors must come from Colors.qml.

Do not introduce arbitrary color literals into individual widgets or layouts when the color belongs to the project's design system.

Avoid:

color: "#ffffff"


when an appropriate project color exists.

Prefer:

color: Colors.text


If a genuinely new semantic color is required, add it to Colors.qml rather than defining it locally.

Use semantic names rather than names tied to a particular widget.

For example, prefer:

Colors.background
Colors.surface
Colors.text
Colors.textMuted
Colors.accent


over:

Colors.workspaceWidgetBlue
Colors.clockWhite


unless the project already follows the latter convention.

Dimensions and spacing

All reusable values for spacing, gaps, padding, margins, sizing, and radii must come from Style.qml.

Before introducing a new value:

Search Style.qml.
Determine whether an existing value can be reused.
If an equivalent value exists, reuse it.
If a genuinely new design token is required, add it to Style.qml.

Do not create arbitrary one-off values when an existing design token represents the same concept.

For example, if the bar already has a corner radius:

Style.radius


then widgets using the same visual treatment should use that same radius rather than introducing another hard-coded radius.

The goal is a coherent design system, not merely centralized constants.

7. Visual Consistency

New elements must visually and structurally follow the patterns established by existing elements, especially the bar.

Reuse existing:

colors
spacing
padding
gaps
corner radii
typography
alignment
margins
interaction states
animations
component composition patterns

Do not create a visually independent component unless the requested feature genuinely requires different behavior.

When uncertain, inspect the closest existing component and replicate its implementation pattern before inventing a new one.

8. Layouts

Follow Qt/QML layout semantics rather than treating QML layouts like CSS.

Prefer the project's existing layout approach.

Use RowLayout, ColumnLayout, GridLayout, anchors, or other layout mechanisms according to the surrounding implementation and the actual geometry requirements.

Avoid unnecessary manual positioning.

Do not mix multiple competing layout systems in the same component without a clear reason.

Keep spacing and padding sourced from Style.qml.

9. State and Reactivity

Prefer declarative QML property bindings over imperative state synchronization.

Prefer:

width: parent.width - Style.padding * 2


over manually updating width from signal handlers.

Do not assign to a property imperatively if doing so unnecessarily breaks an existing binding.

Use signals only where they improve component communication or are required by the underlying API.

Keep state close to the component or service that owns it.

Do not duplicate state that can be derived reactively from an existing source.

10. Quickshell APIs

Prefer native Quickshell APIs over external commands or shell scripts when an appropriate API exists.

Do not assume that an API, property, signal, enum, or type exists.

Before using a Quickshell API:

Verify it in the Quickshell 0.3.0 documentation, or
Verify it in an existing working implementation in this repository.

Do not infer APIs from similarly named Qt, Hyprland, or older Quickshell APIs.

When an API has version-specific behavior, use the behavior documented for Quickshell 0.3.0.

11. Hyprland Integration

Prefer the project's existing Quickshell Hyprland integration.

When interacting with Hyprland:

Prefer native Quickshell Hyprland types when they provide the required functionality.
Use Hyprland IPC only when appropriate.
Do not spawn hyprctl processes repeatedly when an equivalent reactive Quickshell API exists.
Verify Hyprland IPC commands, events, and data formats against the official Hyprland documentation.
Handle state changes reactively rather than relying on polling where possible.

Do not implement Hyprland-specific behavior based solely on assumptions from other window managers.

12. Component Design

Create a reusable QML component when:

the element is used more than once;
the element represents a distinct conceptual UI component;
extracting it makes the parent component substantially easier to understand;
or the existing project architecture uses components for equivalent elements.

Avoid creating components solely to move a few lines of trivial markup elsewhere.

Keep components focused on one responsibility.

Prefer composition over large monolithic QML files.

13. Singletons and Shared Configuration

Use a singleton for globally shared configuration/state only when that matches the existing project architecture.

Colors.qml and Style.qml should remain the authoritative sources for visual design tokens.

Do not create additional global configuration objects merely to avoid passing a small number of properties between components.

14. Error Handling and Defensive Code

Do not hide errors with unnecessary fallback logic.

If a required API or property is unavailable, determine why instead of silently substituting unrelated behavior.

Avoid defensive code that obscures the normal control flow.

For optional external state, handle the unavailable state explicitly and consistently with the rest of the project.

15. Performance

Avoid unnecessary:

timers
polling
process spawning
object creation
signal connections
property bindings
repeated IPC calls

Prefer reactive APIs and existing Quickshell services.

Use lazy loading where appropriate for expensive or initially invisible UI.

Do not optimize prematurely, but do not introduce obvious continuously-running work for state that already has an event-driven API.

16. Implementation Process

For each task, follow this workflow:

Phase 1 — Understand
Read the relevant existing components.
Identify the closest existing implementation pattern.
Check the applicable Quickshell/Qt/Hyprland documentation.
Determine which existing design tokens should be reused.
Phase 2 — Plan

Before making changes, determine:

files that need modification;
files that need creation;
existing components that should be reused;
required state/data sources;
required signals/bindings;
required design tokens.

Avoid unnecessary changes outside the scope of the task.

Phase 3 — Implement

Implement the smallest clean change that satisfies the requirement.

Preserve existing behavior.

Do not refactor unrelated code unless the requested feature requires it.

Phase 4 — Validate

After implementation:

Inspect the complete diff.
Check QML syntax and imports.
Run `scripts/check.sh` from the repo root. It is the project's validation:
formatting, whitespace, qmllint, qmldir completeness, popup namespaces, glyph
integrity, python/lua/shell parsing, the greeter config, and tests/.
Verify that all referenced Quickshell APIs exist.
Verify that new colors are in Colors.qml.
Verify that new spacing/sizing/radius values are in Style.qml.
Verify naming and component structure.
Check for broken property bindings.
Check for unnecessary processes, timers, polling, or IPC.
Fix all issues introduced by the change.

Do not consider a task complete merely because the code was generated successfully.

17. Change Scope

Keep changes focused.

Do not:

rewrite unrelated components;
rename existing APIs without necessity;
introduce new dependencies without justification;
replace working project patterns with personal preferences;
reformat unrelated files;
migrate architecture as part of an unrelated feature.

If a larger architectural change appears necessary, explain the reason before performing it.

18. When Documentation and Existing Code Conflict

If existing code conflicts with current documentation:

Determine whether the existing code depends on version-specific behavior.
Verify the actual installed/project version.
Prefer the documented API for the target version.
Preserve compatibility with existing project architecture where possible.
Do not silently introduce a breaking architectural change.

If the correct choice remains ambiguous, state the ambiguity and choose the smallest reversible implementation.

19. Completion Criteria

A task is complete only when:

the requested behavior works;
the implementation follows existing project patterns;
Quickshell APIs have been verified;
QML naming and structure are correct;
colors are centralized in Colors.qml;
dimensions/spacing/gaps/padding/radii are centralized in Style.qml;
no unnecessary hard-coded design values were introduced;
Hyprland integration follows the project's established approach;
no unrelated behavior was changed;
validation/checks pass or any pre-existing failures are explicitly identified;
the final diff is clean and appropriately scoped.

When reporting completion, summarize:

what changed;
which files changed;
important implementation decisions;
validation performed;
any remaining limitations or pre-existing failures.
