# RouterOS LSP — Architecture & Agent Context

> This file provides deep context for AI agents (Claude Code, Copilot, etc.) working on this codebase.
> For quick reference, see [`.github/copilot-instructions.md`](.github/copilot-instructions.md).
> For design decisions, see [`DESIGN.md`](DESIGN.md).
> For future work, see [`BACKLOG.md`](BACKLOG.md).
> For deployment-context details, see [`.github/instructions/deployment.instructions.md`](.github/instructions/deployment.instructions.md).

## Agent Roles

**Copilot is the primary implementation agent.** It runs in-IDE and as hosted agents on github.com and does most of the routine code changes. **Claude Code is the secondary agent for design and review** — DESIGN.md authorship, architectural decisions, focused refactors, and PR code review. When in doubt, prefer pushing implementation decisions into DESIGN.md (Claude territory) and keep BACKLOG.md actionable (Copilot territory).

This matters for instruction-writing: docs in this repo must be model-agnostic. Where a rule applies to only one, label it `Copilot:` or `Claude:` inline.

## What This Project Does

RouterOS LSP is a Language Server Protocol server for MikroTik RouterOS scripting language (`.rsc` files). Unlike most LSPs that ship with a built-in grammar, this one queries a **live RouterOS device** via HTTP REST API to get all syntax data — meaning it automatically supports any RouterOS version without updates.

This is the **most widely used tikoci project** (thousands of VSCode Marketplace installs). Treat code quality, test coverage, and release hygiene accordingly. "Works on my VSCode Desktop" is not sufficient — changes must hold up across all five deployment contexts below.

## Deployment Contexts (six, not three)

The codebase compiles to three build targets, but each change must be evaluated against six **deployment contexts** where users actually hit it:

1. **VSCode Desktop** (Marketplace + Open-VSX) — the largest user base; Node.js IPC.
2. **VSCode Web** (`vscode.dev`, `github.dev`) — Web Worker; no Node APIs; needs a CORS proxy for RouterOS.
3. **Standalone native binary** (GitHub Releases) — `bun build --compile`; for Helix and other LSP clients via `--stdio`.
4. **npm package** `@tikoci/routeroslsp` — Node-based stdio server; the recommended non-VSCode install path because it avoids macOS quarantine and is platform-independent.
5. **NeoVim** — consumes either the standalone binary or the npm package via stdio, but is first-class: it has its own init script (`nvim-routeros-lsp-init.lua`), its own README section, and its own `.github/instructions/neovim.instructions.md`. Changes to the standalone path must be validated against NeoVim explicitly — it's the canary for "does the stdio transport still work end-to-end outside VSCode".
6. **GitHub Copilot CLI** — consumes the LSP via `.github/lsp.json` (repo-level) or `~/.copilot/lsp-config.json` (user-level). This is an LSP client, not an MCP server; credentials flow through `initializationOptions` because Copilot CLI does not implement `workspace/configuration`.

See [`.github/instructions/deployment.instructions.md`](.github/instructions/deployment.instructions.md) for the per-context pre-release checklist.

## Repository Layout

```
.github/
  copilot-instructions.md   # Copilot workspace instructions (read first)
  instructions/              # File-scoped Copilot instructions (applyTo globs)
  workflows/build.yaml       # CI: build + cross-platform release

client/                      # VSCode extension client (thin binding)
  src/
    extension.ts             # Desktop entry point (IPC transport)
    extension.web.ts         # Web entry point (Worker transport)
    client.ts                # Shared: document selectors, package info
    commands.ts              # VSCode Command Palette actions
    watchdog.ts              # Connection health monitor
    watchdog-errors.ts       # Pure error-mapping functions (extracted for testability)
    watchdog-errors.test.ts  # Tests for toErrorInfo/getTextFromError

server/                      # LSP server (the brain — portable across editors)
  src/                       # RUNTIME CODE ONLY — what ends up in dist/server.js
    server.ts                # Node.js entry point
    server.web.ts            # Browser entry point
    controller.ts            # All LSP protocol handlers (~500 lines)
    model.ts                 # Per-document state, caching, async token fetching
    routeros.ts              # HTTP client for RouterOS REST API
    shared.ts                # Settings, logging, credential management
    tokens.ts                # Token parser for /console/inspect highlight data
    *.test.ts                # Unit tests — co-located TODAY (planned to move; see BACKLOG)
    test-preload.ts          # Bun test preload — silences log output (planned to move with tests)
    capture-snapshots.ts     # ⚠️ Script, not runtime. Planned to move to scripts/
    assess-dataset.ts        # ⚠️ Script, not runtime. Planned to move to scripts/
    profile-timing.ts        # ⚠️ Script, not runtime. Planned to move to scripts/
    import-discourse-*.ts    # ⚠️ Scripts, not runtime. Planned to move to scripts/
    integration.test.ts      # CHR integration tests (skipped when no CHR)
    snapshot.test.ts         # Offline tests against .rsc.highlight snapshot pairs

test-data/                   # .rsc scripts + .highlight snapshots for testing
  edge-cases/                # Targeted: empty, comment-only, single-command, oversize, unicode
  eworm/                     # Scripts from eworm-de/routeros-scripts (GPL, attributed)
  forum/                     # Scripts sourced from forum.mikrotik.com
  *.rsc.highlight            # Saved highlight responses for offline snapshot tests
docs/                        # User-facing docs (walkthrough, CORS guide)

bunfig.toml                  # Bun config — test preload for log silencing
nvim-routeros-lsp-init.lua   # NeoVim LSP configuration script
build-standalone.sh          # Cross-platform bun compile loop
webpack.config.js            # Web target bundling only
.scratch/                    # Gitignored — ad-hoc experiments, one-off probes
scripts/                     # PLANNED — tooling scripts (capture, profile, assess, import)
tests/                       # PLANNED — tests, moved out of client/src + server/src
```

## Architecture

### Three Build Targets

The same server code compiles to three targets:

| Target | Entry | Transport | Build |
|--------|-------|-----------|-------|
| VSCode Desktop | `server.ts` | Node IPC | `bun build` → CJS |
| VSCode Web | `server.web.ts` | BrowserMessageReader/Writer | `webpack` → Web Worker |
| Standalone | `server.ts` | `--stdio` / `--socket` | `bun build --compile` → native binary |

The client only exists for VSCode (desktop + web). Other editors use the standalone binary directly.

### Server Architecture

```
┌──────────────────────────────────────────────────────────┐
│  server.ts / server.web.ts                                │
│  Creates LSP Connection → passes to LspController         │
├──────────────────────────────────────────────────────────┤
│  controller.ts (LspController)                            │
│  ├── onInitialize() — negotiate capabilities              │
│  ├── onCompletion() — query /console/inspect completion   │
│  ├── onDiagnostics() — parse error tokens                 │
│  ├── onSemanticTokens() — map highlight data              │
│  ├── onHover() — show token type + regex viz              │
│  ├── onDocumentSymbols() — extract variables              │
│  └── onExecuteCommand() — server commands                 │
├──────────────────────────────────────────────────────────┤
│  model.ts (LspDocument)                                   │
│  Wraps TextDocument + lazy async highlight tokens cache    │
├──────────────────────────────────────────────────────────┤
│  routeros.ts (RouterRestClient)                           │
│  POST /rest/console/inspect {request, input, path}        │
│  GET  /rest/system/identity                               │
│  POST /rest/execute {script}                              │
├──────────────────────────────────────────────────────────┤
│  tokens.ts (HighlightTokens)                              │
│  Parses comma-delimited highlight response → tokenRanges  │
├──────────────────────────────────────────────────────────┤
│  shared.ts                                                │
│  Settings resolver, logging, credential override logic    │
└──────────────────────────────────────────────────────────┘
```

### Singleton Pattern

Both `LspController` and `RouterRestClient` use static `.default` singletons. One controller per session. One HTTP client per session (with Axios interceptors for logging/error recovery).

### Document Lifecycle

1. `onDidOpenTextDocument` → create `LspDocument` in `#lspDocuments` Map
2. `LspDocument` lazily fetches `highlightTokens` via `RouterRestClient.inspect('highlight', ...)`
3. Tokens cached until document changes → `onDidChangeTextDocument` → invalidate + re-fetch
4. On config change → all documents refreshed (clear cache, re-fetch)

### RouterOS API Interaction

All data comes from `POST /rest/console/inspect`:

| `request` value | What it returns | Used for |
|-----------------|----------------|----------|
| `highlight` | Token type per character (comma-separated) | Semantic tokens, diagnostics |
| `completion` | Completion items at cursor | Code completion |
| `syntax` | Command structure (dirs, cmds, args) | Not yet used (documented in README) |
| `child` | Child nodes of a path | Not yet used |

**Key gotchas:**
- RouterOS uses Windows-1252 encoding; the LSP converts non-ASCII (>127) to `?` before querying
- Documents >32KB are truncated (RouterOS API limit)
- Adding a fake space or `=` after input can expose arg completions or value definitions (see README "Implementation Tips")
- Response format varies significantly between `request` types — `highlight` is comma-delimited, others are structured JSON

### Client Architecture (VSCode Only)

The client is intentionally thin:
- `extension.ts` / `extension.web.ts` — Create `LanguageClient`, register commands, start watchdog
- `client.ts` — Document selectors for `.rsc`, `.tikbook`, notebook cells; multiple URI schemes
- `commands.ts` — Theme color application, settings navigation, new file creation
- `watchdog.ts` — Periodic `getIdentity()` ping with error mapping (ECONNREFUSED, 401, TLS, timeout)

### TikBook Integration

[vscode-tikbook](https://github.com/tikoci/tikbook) is the companion extension:
- TikBook includes this LSP in its `extensionPack`
- When `allowClientProvidedCredentials` is `true` (default), TikBook can override credentials via `routeroslsp.server.useConnectionUrl` command
- The watchdog detects this and adjusts error messages accordingly
- Document selectors include `rscena` URI scheme and tikbook file patterns for cross-extension support

## Build System

### Why Bun + Webpack

- **Bun** handles Node.js compilation (`bun build`) and standalone binary (`bun build --compile`)
- **Webpack** is required only for the web target (Web Worker bundling with polyfills like `path-browserify`)
- This is an intentional split: Bun can't bundle Web Workers, webpack can't compile standalone binaries

### Build Scripts

| Script | What it does |
|--------|-------------|
| `compile` | Full build: client + server + exe + web |
| `compile:client` | `bun build client/src/extension.ts` → CJS |
| `compile:server` | `bun build server/src/server.ts` → CJS |
| `compile:exe` | `bun build --compile server/src/server.ts` → native binary |
| `compile:web` | `webpack` → Web Worker bundles |
| `watch:node` | Dev mode: compile + watch server changes |
| `watch:web` | Dev mode: webpack watch |
| `vsix:package` | Package .vsix (runs compile + vsce) |
| `vsix:package:prerelease` | Package .vsix as pre-release (`--pre-release`) |
| `bun:exe` | Same as compile:exe + copies to ~/.bin/ |
| `lint` | `bun audit` + Biome check on server + client |
| `test` | `bun test server/src/ client/src/` |
| `bump:patch` | Sync patch version across root + server + client package.json |
| `bump:minor` | Sync minor version across root + server + client package.json |
| `npm:publish` | `compile:server` + prepend shebang + `npm publish` from server/ |

### CI (`build.yaml`)

GitHub Actions workflow (manual trigger):
1. Setup Node 22 + Bun (with `registry-url` set for npm auth)
2. Install, build, lint
3. Package VSIX
4. Cross-compile standalone binaries for 8 platforms (Linux x64/arm64, macOS x64/arm64, Linux musl, Windows x64/arm64)
5. Create GitHub Release with all artifacts
6. Publish VSIX to VSCode Marketplace and Open-VSX
7. Publish server package to npm as `@tikoci/routeroslsp` (if `NPM_TOKEN` secret is set)

## Code Patterns

### Error Handling
- HTTP interceptors clear document cache on errors → forces re-fetch on next request
- `RouterOSClientError` interface (`code`, `message`, `status`) is the normalized error shape that crosses the LSP protocol boundary — avoids circular-reference crashes when serializing over JSON-RPC
- `normalizeError()` in `routeros.ts` converts `AxiosError`/`Error`/unknown into a plain `RouterOSClientError`
- `inspect*` and `execute` methods return `undefined` on error (graceful degradation); `getIdentity` propagates the error (watchdog needs it)
- Diagnostics degrade gracefully: no tokens = empty array + log
- Watchdog maps error codes to user-friendly messages with action buttons; `toErrorInfo()` helper safely extracts fields from any error shape

### Async Patterns
- `readyResolver` Promise gates all handlers until initialization completes
- `LspDocument.highlightTokens` is a lazy Promise — evaluated once, cached until invalidated
- All LSP handlers `await controller.isReady` before processing

### Logging
- `log.debug()`, `log.info()`, `log.warn()`, `log.error()` from `shared.ts`
- Backed by LSP `connection.console.*`
- HTTP request/response logging in Axios interceptors

## Testing

Tests use `bun test` with co-located `*.test.ts` files. Run with `bun test server/src/ client/src/` or `bun run test`.

### Test tiers

| Tier | Files | What it tests | CHR required? |
|------|-------|---------------|---------------|
| Unit | `controller.test.ts`, `tokens.test.ts`, `routeros.test.ts`, `shared.test.ts` | Pure functions, static methods, settings lifecycle | No |
| Model | `model.test.ts` | `LspDocument.diagnostics()` with mocked `inspectHighlight` | No |
| Snapshot | `snapshot.test.ts` | Token parsing against saved `.rsc.highlight` files | No |
| Client | `watchdog-errors.test.ts` | `toErrorInfo`/`getTextFromError` error mapping | No |
| Integration | `integration.test.ts` | Full highlight pipeline against live CHR for all `test-data/**/*.rsc` | Yes |

### Key details

- `bunfig.toml` configures a preload (`test-preload.ts`) that silences `log.*` output during tests
- Integration tests auto-skip when no CHR is reachable (default `http://192.168.74.150`, override via `ROUTEROS_TEST_URL`)
- `capture-snapshots.ts` is a CLI tool (`bun run server/src/capture-snapshots.ts`) that regenerates `.highlight` snapshot files from a live CHR
- `test-data/` is committed — snapshot `.highlight` files and scripts are available in CI for offline tests
- Snapshot tests revealed unknown token types `arg-scope`, `arg-dot` — not yet in `HighlightTokens.TokenTypes` (see BACKLOG)
- See [BACKLOG.md](BACKLOG.md) for remaining testing work (VSCode integration tests, CI snapshot capture)

## CHANGELOG.md

`CHANGELOG.md` is user-facing — it's displayed as "Release Notes" in the VSCode extension UI. Write for extension users, not developers.

Each release has **Changes** (user-visible features/improvements) and **Fixes** (bug fixes). Update the changelog when making user-visible changes. Don't log version bumps, CI-only changes, or individual lint fixes. Refactors are worth a summarized bullet under Fixes since users may correlate behavior changes. See `.github/instructions/changelog.instructions.md` for full conventions.

## LSP Capabilities Implemented

| LSP Feature | Status | Handler in controller.ts |
|-------------|--------|--------------------------|
| Completion | ✅ Working | `#onCompletion` |
| Semantic Tokens | ✅ Working | `#generateSemanticTokens` |
| Diagnostics | ✅ Working | `#handleDiagnostics` |
| Hover | ⚠️ Basic (shows token type) | `#onHover` |
| Document Symbols | ⚠️ Basic (variables only) | `#onDocumentSymbols` |
| Execute Commands | ✅ Working (6 commands) | `onExecuteCommand` |
| Inlay Hints | 🚫 Removed (dead code cleaned up) | — |
| Definition/References | 🚫 Not implemented | — |
| Formatting | 🚫 Not implemented | — |
| Code Actions | 🚫 Not implemented | — |

See [BACKLOG.md](BACKLOG.md) for planned LSP feature additions.

## Known Gotchas

1. **Handler naming**: Handlers are private class methods (`#onCompletion`, `#onHover`, etc.) — not public or arrow-function properties. Don't reference old names like `onCompletionHandler`.
2. **32KB document limit**: RouterOS API truncates large scripts. The LSP silently truncates at this boundary.
3. **Unicode → underscore replacement**: Non-ASCII characters replaced with `?` before sending to RouterOS. Character indexes must be preserved carefully.
4. **Self-signed TLS**: Node.js uses `rejectUnauthorized: false` by default. Web target cannot bypass certificate checks — requires CORS proxy.
5. **Full document sync**: Every keystroke sends the full document to RouterOS for re-highlighting. No incremental sync.
6. **No offline mode**: Without a RouterOS connection, the LSP does nothing. Don't try to add fallback syntax — it would be version-specific and wrong.
7. **Webpack for web only**: Don't try to use webpack for the Node target or bun for the web target.

## Related Projects

| Project | Relation | What to know |
|---------|----------|-------------|
| [tikoci/tikbook](https://github.com/tikoci/tikbook) | Companion VSCode extension | Credential sharing, extensionPack dependency |
| [tikoci/restraml](https://github.com/tikoci/restraml) | REST API schema generator | Shares `/console/inspect` knowledge, QEMU CHR patterns |
| [tikoci/netinstall](https://github.com/tikoci/netinstall) | Device flasher | REST API gotchas, QEMU VM bridging |
| [tikoci.github.io](https://tikoci.github.io) | Portfolio site | All tikoci tools index |
| [tikoci/routeros-skills](https://github.com/tikoci/routeros-skills) | Copilot skills | RouterOS domain knowledge for agents |
