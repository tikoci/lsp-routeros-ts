---
description: "Conventions for updating CHANGELOG.md. This is a user-facing document shown in the VSCode extension UI — not a git log."
applyTo: "CHANGELOG.md"
---

# CHANGELOG.md Conventions

CHANGELOG.md is displayed to users in the VSCode extension UI ("Release Notes"). Write for extension users, not developers.

## Structure

Each release has two optional sections — use whichever apply:

- **Changes** — user-visible features, improvements, or behavior changes. Write from the user's perspective: "Improved NeoVim support, including Lazy.nvim compatibility" not "Added `vim.schedule()` call in init script".
- **Fixes** — bug fixes and corrections. Summarize code cleanup or refactors in one bullet when relevant (users may want to correlate behavior changes with refactored code).

## What to include

- Features or settings a user would interact with
- Bug fixes that affected user-visible behavior
- Refactors that touched significant code paths (summarized — helps users correlate if they see new issues)
- Breaking changes (renamed binaries, changed config paths, removed settings)

## What NOT to include

- Version bumps (`bump:patch`, `bump:minor`) — that's what the version heading already says
- CI/build pipeline changes unless they affect what users receive (e.g. package size, new platforms)
- Individual lint fixes, typo corrections, or import cleanup — summarize as "Code cleanup" if worth mentioning at all
- Git commit messages pasted verbatim — rewrite for the audience

## Style

- Keep bullets concise — one or two lines each
- Group related items into a single bullet with sub-items when natural
- Git commit SHAs or PR numbers are fine to include for traceability but not required
- Use `code formatting` for setting names, file names, and CLI commands users would type
