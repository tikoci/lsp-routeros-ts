# RouterOS LSP — Architecture & Agent Context

> This file provides deep context for AI agents (Claude Code, Copilot, etc.) working on this codebase.
> For quick reference, see [`.github/copilot-instructions.md`](.github/copilot-instructions.md).
> For design decisions, see [`DESIGN.md`](DESIGN.md).
> For future work, see [`BACKLOG.md`](BACKLOG.md).

## What This Project Does

RouterOS LSP is a Language Server Protocol server for MikroTik RouterOS scripting language (`.rsc` files). Unlike most LSPs that ship with a built-in grammar, this one queries a **live RouterOS device** via HTTP REST API to get all syntax data — meaning it automatically supports any RouterOS version without updates.

Published as:
- **VSCode Extension** on [Marketplace](https://marketplace.visualstudio.com/items?itemName=TIKOCI.lsp-routeros-ts) (~thousands of users)
- **Standalone binary** via [GitHub Releases](https://github.com/tikoci/lsp-routeros-ts/releases) (NeoVim, other editors)
- **Web extension** for `vscode.dev` and `github.dev` (requires CORS proxy)

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

server/                      # LSP server (the brain — portable across editors)
  src/
    server.ts                # Node.js entry point
    server.web.ts            # Browser entry point
    controller.ts            # All LSP protocol handlers (~850 lines)
    model.ts                 # Per-document state, caching, async token fetching
    routeros.ts              # HTTP client for RouterOS REST API
    shared.ts                # Settings, logging, credential management
    tokens.ts                # Token parser for /console/inspect highlight data

test-data/                   # Sample .rsc and .tikbook files
tests/                       # Test .rsc files (no test runner yet)
docs/                        # User-facing docs (walkthrough, CORS guide)

nvim-routeros-lsp-init.lua   # NeoVim LSP configuration script
build-standalone.sh          # Cross-platform bun compile loop
webpack.config.js            # Web target bundling only
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
| `bun:exe` | Same as compile:exe + copies to ~/.bin/ |
| `lint` | `bun audit` + ESLint on server + client |

### CI (`build.yaml`)

GitHub Actions workflow (manual trigger):
1. Setup Node 22 + Bun
2. Install, build, lint
3. Package VSIX
4. Cross-compile standalone binaries for 8 platforms (Linux x64/arm64, macOS x64/arm64, Linux musl, Windows x64/arm64)
5. Create GitHub Release with all artifacts

## Code Patterns

### Error Handling
- HTTP interceptors clear document cache on errors → forces re-fetch on next request
- Diagnostics degrade gracefully: no tokens = empty array + log
- Watchdog maps error codes to user-friendly messages with action buttons

### Async Patterns
- `readyResolver` Promise gates all handlers until initialization completes
- `LspDocument.highlightTokens` is a lazy Promise — evaluated once, cached until invalidated
- All LSP handlers `await controller.isReady` before processing

### Logging
- `log.debug()`, `log.info()`, `log.warn()`, `log.error()` from `shared.ts`
- Backed by LSP `connection.console.*`
- HTTP request/response logging in Axios interceptors

## Testing Status

**No automated tests exist yet.** Test infrastructure is a planned addition:
- `test-data/` has sample `.rsc` and `.tikbook` files for manual testing
- `tests/` has `.rsc` files used for manual LSP behavior verification
- The `mocha` devDependency exists but no test runner is configured
- See [BACKLOG.md](BACKLOG.md) for planned testing strategy

## LSP Capabilities Implemented

| LSP Feature | Status | Handler in controller.ts |
|-------------|--------|--------------------------|
| Completion | ✅ Working | `onComletionHandler` (note: typo in code) |
| Semantic Tokens | ✅ Working | `generateSemanticTokens` |
| Diagnostics | ✅ Working | `handleDiagnostics` |
| Hover | ⚠️ Basic (shows token type) | `onHoverHandler` |
| Document Symbols | ⚠️ Basic (variables only) | `onDocumentSymbols` |
| Execute Commands | ✅ Working (6 commands) | `onExecuteCommand` |
| Inlay Hints | 🚫 Disabled (commented out) | — |
| Definition/References | 🚫 Not implemented | — |
| Formatting | 🚫 Not implemented | — |
| Code Actions | 🚫 Not implemented | — |

See [BACKLOG.md](BACKLOG.md) for planned LSP feature additions.

## Known Gotchas

1. **Completion handler typo**: `onComletionHandler` (missing 'p') — preserved for compatibility, don't rename without search
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
