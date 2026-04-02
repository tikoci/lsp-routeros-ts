# RouterOS LSP — Workspace Instructions

## Reading Order

1. **This file** — overview and quick reference
2. **[CLAUDE.md](../CLAUDE.md)** — full architecture, design decisions, and patterns
3. **[DESIGN.md](../DESIGN.md)** — design rationale and cross-project patterns
4. **[BACKLOG.md](../BACKLOG.md)** — future work and task tracking
5. **`.github/instructions/`** — file-scoped rules loaded automatically by `applyTo` globs

## Project Overview

RouterOS LSP is a Language Server Protocol implementation for MikroTik RouterOS scripts. It queries a **live RouterOS device** via `/console/inspect` REST API to provide syntax highlighting, completion, diagnostics, hover, and symbols.

**Three build targets** from one codebase:
- **VSCode Desktop** — Node.js IPC transport (`client/src/extension.ts` → `server/src/server.ts`)
- **VSCode Web** — Web Worker transport via webpack (`client/src/extension.web.ts` → `server/src/server.web.ts`)
- **Standalone** — Bun-compiled binary for NeoVim and other LSP clients (`server/src/server.ts --stdio`)

## Build & Dev

```bash
bun install                 # Install all deps (chains client + server)
bun run compile             # Full build (client + server + exe + web)
bun run watch:node          # Dev mode — rebuild server on changes
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
