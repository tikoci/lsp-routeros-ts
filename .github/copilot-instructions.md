# RouterOS LSP — Workspace Instructions

## Reading Order

1. **This file** — overview and quick reference
2. **[CLAUDE.md](../CLAUDE.md)** — full architecture, design decisions, and patterns
3. **[DESIGN.md](../DESIGN.md)** — design rationale and cross-project patterns
4. **[BACKLOG.md](../BACKLOG.md)** — future work and task tracking
5. **`.github/instructions/`** — file-scoped rules loaded automatically by `applyTo` globs

## Agent Roles

This project is used by thousands of VSCode users — the bar is higher than for other tikoci projects. Two agent systems share the work:

- **GitHub Copilot (primary)** — implementation, routine edits, PR authoring. Runs both in the IDE and as hosted agents on github.com, which means changes must not assume a local dev environment is present.
- **Claude Code (secondary)** — design work (DESIGN.md, architectural decisions), code review on PRs, deeper refactors. Claude is invoked deliberately; Copilot is the default.

Both agents read this file and CLAUDE.md — keep instructions model-agnostic. When something only applies to one, label it inline (e.g. `Copilot:` / `Claude:`).

## Project Overview

RouterOS LSP is a Language Server Protocol implementation for MikroTik RouterOS scripts. It queries a **live RouterOS device** via `/console/inspect` REST API to provide syntax highlighting, completion, diagnostics, hover, and symbols.

**Three build targets, six deployment contexts.** The build targets collapse to one codebase; the deployment contexts are where the user-facing failure modes live. Track both.

| Build target | Deployment context | Entry | Transport | First-class artifact |
|---|---|---|---|---|
| Client+Server CJS | VSCode Desktop | `extension.ts` → `server.ts` | Node IPC | `package.json` + VSIX |
| Web bundles | VSCode Web (`vscode.dev`, `github.dev`) | `extension.web.ts` → `server.web.ts` | Web Worker | webpack bundles |
| Server CJS | npm package `@tikoci/routeroslsp` | `server.ts` | stdio (via `routeroslsp` bin) | `server/package.json` |
| Native binary | Standalone download (Helix, other LSP clients) | `server.ts --stdio` | stdio / `--socket=<port>` | `build-standalone.sh`, GitHub Releases |
| Native binary / npm | **NeoVim** | `server.ts --stdio` | stdio | `nvim-routeros-lsp-init.lua` |
| Server CJS | GitHub Copilot CLI | `server.ts` | stdio, reads `initializationOptions` | `.github/lsp.json` |

NeoVim shares the transport with "generic standalone" but has its own first-class config artifact, its own README section, and its own `neovim.instructions.md` — changes to the standalone path must be validated against NeoVim explicitly.

Full per-context gotchas and pre-release checks: [`deployment.instructions.md`](instructions/deployment.instructions.md).

## Build & Dev

```bash
bun install                 # Install all deps (chains client + server)
bun run compile             # Full build (client + server + exe + web)
bun run watch:node          # Dev mode — rebuild server on changes
bun run test                # Run all tests (unit + snapshot + model + client)
bun run lint                # ESLint
bun run vsix:package        # Package .vsix for VSCode Marketplace
bun run bun:exe             # Build standalone binary (copies to ~/.bin/)
```

**F5** in VSCode launches the Extension Development Host (preLaunchTask: `compile`).

## Critical Conventions

- **Bun over Node.js** — `bun install`, `bun run`, `bun build`, `bun test`
- **Tabs** for indentation, **single quotes** for strings (see `.vscode/settings.json`)
- **No `console.log`** in extension code — use LSP `connection.console` or `log.*` helpers in `shared.ts`
- **Server is the brain** — LSP features belong in `server/`, not `client/`. The client is a thin VSCode binding that proxies to the server. Don't replace LSP protocol with VSCode-specific APIs.
- **All syntax data comes from RouterOS** — the LSP has no built-in grammar. Every completion, diagnostic, and token comes from querying a live device's `/console/inspect` endpoint.
- **Three ID conventions**: `lsp-routeros-ts` (project), `routeroslsp` (settings/config namespace), `lsp-routeros-server-*` (standalone binaries)
- **`client/src/` and `server/src/` hold runtime code only** — what ships in `dist/`. Tests (`*.test.ts`) are co-located today for historical reasons but are planned to move; **do not add new tests or one-off scripts to `server/src/`**. New tooling scripts go in a top-level `scripts/` directory (create it if needed); ad-hoc experimentation goes in `.scratch/` (gitignored). See the "Repository Structure" items in [BACKLOG.md](../BACKLOG.md).
- **Pre-release quality gate** — before `vsix:package:prerelease` or an npm publish can be trusted, the five deployment contexts above all need at least a smoke check green. See [`deployment.instructions.md`](instructions/deployment.instructions.md#pre-release-checklist).

## Key Files

| Purpose | Path |
|---------|------|
| LSP controller (all handlers) | `server/src/controller.ts` |
| RouterOS HTTP client | `server/src/routeros.ts` |
| Document model & caching | `server/src/model.ts` |
| Token parser & highlighting | `server/src/tokens.ts` |
| Settings & logging | `server/src/shared.ts` |
| VSCode commands | `client/src/commands.ts` |
| Connection watchdog | `client/src/watchdog.ts` |
| Watchdog error mapping (pure) | `client/src/watchdog-errors.ts` |
| NeoVim integration | `nvim-routeros-lsp-init.lua` |

## Cross-Project Context

- **[vscode-tikbook](https://github.com/tikoci/tikbook)** — companion extension providing notebooks; shares credentials via `allowClientProvidedCredentials`
- **[restraml](https://github.com/tikoci/restraml)** — generates RAML/OpenAPI schemas from RouterOS; shares `/console/inspect` API knowledge
- See `~/CLAUDE.md` "RouterOS Cross-Project Knowledge" table for full map

## What NOT to Do

- Don't add a built-in grammar/syntax database — the live RouterOS connection IS the grammar
- Don't move LSP protocol features to the client — keep the server portable across editors
- Don't use `npm`/`npx` — use `bun`/`bunx`
- Don't add frameworks or heavy dependencies — keep it lean for all three targets
- Don't hardcode RouterOS commands or paths — they vary by version
