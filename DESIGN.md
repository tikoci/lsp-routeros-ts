# RouterOS LSP — Design Decisions

> Design rationale and cross-project patterns. For architecture details, see [`CLAUDE.md`](CLAUDE.md). For per-deployment-context gotchas, see [`.github/instructions/deployment.instructions.md`](.github/instructions/deployment.instructions.md).

## Agent Roles (Copilot primary, Claude secondary)

The project uses two agent systems. The split is deliberate:

- **Copilot** handles routine implementation. It runs in-IDE and as hosted agents on github.com, so changes must not assume a local dev environment or maintainer-only context.
- **Claude Code** handles design and review — this file, architectural decisions, focused refactors, and PR code review.

The rule of thumb for where something belongs: if it's actionable next-step work, BACKLOG.md (Copilot-friendly). If it's a decision with tradeoffs worth justifying, this file (Claude-friendly). Both agents read both documents; labelling is for discipline, not access control.

## Core Design Principle: The Router IS the Grammar

The fundamental design decision is that the LSP has **no built-in syntax knowledge**. All completions, diagnostics, semantic tokens, and hover data come from querying a live RouterOS device's `/console/inspect` REST endpoint.

**Why:**
- RouterOS adds/removes/changes commands across versions
- Maintaining a grammar file would be a constant catch-up game
- The router already has the authoritative grammar — use it
- Users connect to the specific version they're writing scripts for

**Trade-offs:**
- Requires a live RouterOS connection (no offline mode)
- Latency depends on network speed to the router
- Each keystroke triggers HTTP requests (mitigated by caching)
- Can't provide features without RouterOS context (e.g., code actions that don't need live data)

## Client/Server Split

The server must be portable across editors (VSCode, NeoVim, any LSP client). All intelligence lives in `server/`.

**Rules:**
- LSP protocol features → `server/src/controller.ts` handlers
- VSCode-specific UI (commands, notifications, progress) → `client/src/commands.ts`
- Connection health monitoring → `client/src/watchdog.ts` (uses LSP execute commands, not direct HTTP)
- Document selectors and editor integration → `client/src/client.ts`

**What goes where when adding features:**

| Feature type | Goes in | Why |
|-------------|---------|-----|
| New LSP capability (hover, formatting, etc.) | `server/src/controller.ts` | Works in all editors |
| New VSCode command | `client/src/commands.ts` + `package.json` | VSCode UI only |
| New RouterOS API call | `server/src/routeros.ts` | Shared by all LSP features |
| New token parsing logic | `server/src/tokens.ts` | Shared by semanticTokens + diagnostics |
| Settings/configuration | `server/src/shared.ts` + `package.json` | LSP protocol handles settings delivery |
| New completion trigger | `server/src/controller.ts` capabilities | Must be declared in server capabilities |

## Three Build Targets, Five Deployment Contexts

The codebase compiles to three build targets, but ships through six deployment contexts (VSCode Desktop, VSCode Web, standalone binary, npm package, NeoVim, Copilot CLI). The distinction matters: context-specific failures (shebang missing on npm, CORS on web, quarantine on standalone, NeoVim API drift in the init script, missing `workspace/configuration` support on Copilot CLI) are invisible to unit tests. See [`.github/instructions/deployment.instructions.md`](.github/instructions/deployment.instructions.md) for the matrix.

### Why Three Build Targets?

1. **VSCode Desktop** — Primary user base. Node.js IPC for performance.
2. **VSCode Web** — `vscode.dev`/`github.dev` support. Requires webpack + Web Worker.
3. **Standalone binary** — NeoVim and other editors. Bun-compiled native binary.

### Why Bun + Webpack (Not Just One)

Bun handles Node.js compilation and standalone binaries excellently. But it cannot bundle Web Workers with browser polyfills (`path-browserify`, etc.). Webpack handles only the web target.

**Rule:** Don't try to unify to a single bundler. The split is intentional and correct.

### Standalone Binary Constraints

The standalone binary uses `bun build --compile` targeting multiple platforms. It reads settings via LSP `workspace/configuration` protocol — not environment variables or config files. The NeoVim integration script (`nvim-routeros-lsp-init.lua`) provides the configuration handler on the client side.

### Standalone Distribution: npm vs. Native Binary

Two distribution methods are supported for the standalone server:

1. **npm package (`@tikoci/routeroslsp`)** — Preferred for most users. Publishes the compiled `server/dist/server.js` with a `routeroslsp-langserver` bin shim. Install with `npm install -g @tikoci/routeroslsp`. Advantages: no platform-specific filenames, avoids macOS Gatekeeper quarantine for downloaded binaries, auto-updates with `npm update`, works anywhere Node.js is installed.

2. **Native binary (GitHub Releases)** — For environments without Node.js (embedded Linux, minimal setups). Built with `bun build --compile` per platform. Disadvantage: macOS users must remove quarantine attribute after download.

**Rule:** Keep the npm package as the primary documented install path. The native binary is a secondary option, not the default.

## HTTP Client Design

### Why Axios (Not Fetch)

- Axios was chosen for its interceptor pattern (request/response logging, error cache clearing)
- Supports custom HTTPS agents (`rejectUnauthorized: false` for self-signed certs)
- Works in both Node.js and browser contexts (important for web target)
- Changing to fetch would require reimplementing interceptors and HTTPS agent configuration

### Caching Strategy

- Document tokens cached per-URI in `LspController.#lspDocuments` Map
- Cache invalidated on: document change, config change, HTTP error
- HTTP interceptors clear all document caches on any error → forces clean re-fetch
- No HTTP-level response caching (RouterOS doesn't set cache headers)

### Unicode/Encoding

RouterOS uses Windows-1252 encoding internally. The LSP converts non-ASCII characters (code > 127) to `?` before sending to `/console/inspect`. Character positions must be preserved — the replacement is same-length. This is in `RouterScriptPreprocessor.unicodeCharReplace()`.

## Semantic Token Mapping

RouterOS `/console/inspect` returns highlight types that don't map 1:1 to LSP semantic token types. The `package.json` declares custom `semanticTokenTypes` (e.g., `dir`, `cmd`, `arg`, `varname-local`) with `superType` mappings to standard LSP types.

The theme file (`vscode-routeroslsp-theme.json`) provides RouterOS CLI-matching colors that users can override via the "Apply Semantic Color Overrides" command.

## Credential Flow

```
User Settings (routeroslsp.*)
       ↓
  [allowClientProvidedCredentials?]
    ↓ yes                ↓ no
TikBook can override   Always use settings
via executeCommand
       ↓
shared.ts resolves →  RouterRestClient.default
                         ↓
                   Axios with Basic Auth
```

TikBook holds credentials in `SecretStorage` and passes them to the LSP via `routeroslsp.server.useConnectionUrl` command. The LSP server stores the override in memory (not persisted).

## Future Design Considerations

### Adding `request=syntax` Support

`/console/inspect` with `request=syntax` provides richer metadata (descriptions, type definitions) but requires "tricks":
- Adding a fake space after `input=` exposes argument names
- Adding `=` exposes value definitions/enums
- The `TEXT` field format varies wildly (prose, expressions, ranges)

This is documented in README.md under "Implementation Tips" and is the key to improving hover and signature help.

### Copilot/AI Integration

Future work on Copilot integration considerations:
- The LSP could expose RouterOS context (connected version, available commands) as tool contexts
- Code actions could suggest RouterOS-specific fixes (deprecated command replacement, etc.)
- The `/console/inspect request=syntax` TEXT field could provide LLM-consumable descriptions
- Cross-extension with TikBook: TikBook handles notebook execution, LSP handles language intelligence
- **Copilot CLI is already a consumer** — `.github/lsp.json` makes the LSP available to Copilot CLI as a plain LSP server (not an MCP server). The credential path (`initializationOptions` since Copilot CLI doesn't implement `workspace/configuration`) is load-bearing and must be preserved.
- **`tikoci/rosetta` docs integration** — rosetta exposes RouterOS docs as FTS5 over MCP. Open question: does the LSP call rosetta directly, or does a higher layer (TikBook, a Copilot skill) join LSP data with rosetta data? Adding a dependency pulls rosetta into every VSCode install; keeping the LSP pure and exposing a capability lets callers decide. Leaning toward the latter.

### `[:parse <script>]` as a Signal Source

RouterOS exposes a `:parse` operator that returns a `code`-typed internal representation (a stack-based IL) for a script. Open questions worth a research spike before any production use:

- Is parse time predictive of highlight time? The ~28KB inflection point found in `profile-timing.ts` could be avoidable if `:parse` is cheap and correlates — the LSP could defer full highlight on suspected-oversize inputs.
- Does the IL expose scope/block boundaries useful for LSP features that `highlight` can't easily support — folding ranges, definition/references for `:local`/`:global`, control-flow-aware diagnostics?
- Could it serve as an agent-facing debug surface (inspect the parsed form of a script under edit)?

Land the probe in `.scratch/` first; promote to DESIGN if the answers are worth committing to.

### QEMU CHR for Testing

For automated testing, a temporary RouterOS CHR instance can be booted via QEMU:
- Pattern documented in `restraml` project (see `~/GitHub/restraml/CLAUDE.md`)
- QEMU user-mode networking with port forwarding (host:9180→VM:80)
- Wait-for-boot loop checking REST API availability
- Enables version-specific testing without a physical router
