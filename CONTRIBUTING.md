# Contributing to RouterOS LSP

Pull requests are welcome. This document covers building from source, project structure, and implementation details useful for contributors.

## Building from Source

All builds use [Bun](https://bun.sh):

1. Clone the repository: `git clone https://github.com/tikoci/lsp-routeros-ts.git`
2. Install dependencies: `bun install`
3. Build: `bun run compile`

The compiled LSP server is available at `./server/dist/server.js` and can be executed with Node.

### Packaging Options

**VSCode Extension (VSIX):**

```bash
bun run vsix:package    # Creates lsp-routeros-ts-*.vsix
code --install-extension lsp-routeros-ts-*.vsix
```

**Standalone Server (for NeoVim and other editors):**

```bash
bun run bun:exe    # Creates lsp-routeros-server binary for your platform, copies to ~/.bin/
```

The standalone server supports these transport options:

- `--stdio` — Standard input/output (used by NeoVim and most LSP clients)
- `--node-ipc` — Node IPC (used by VSCode)
- `--socket=<port>` — TCP socket (experimental)

### Developing with VSCode

1. Clone and open the repository in VSCode
2. Run `bun run watch:node` in a terminal to rebuild on changes
3. Press <kbd>F5</kbd> to launch the "Extension Development Host"
4. Open a `.rsc` file and test LSP features

For detailed extension debugging, see the [VSCode Extension Debugging Guide](https://code.visualstudio.com/api/get-started/extension-anatomy#extension-files-structure).

### Developer Scripts

The LSP uses `bun run` scripts defined in `package.json`:

- `compile` — Build all components
- `watch:node` — Rebuild server on file changes
- `vsix:package` — Package VSCode extension
- `bun:exe` — Build standalone server binary and copy to `~/.bin/`
- `lint` — Run Biome checks on code
- `test` — Run unit and snapshot tests

## Project Structure

**Source:**

```text
client/src/          — VSCode extension client code
server/src/          — LSP server implementation
  controller.ts      — LSP protocol handler
  server.ts          — Main LSP entry point
  model.ts           — RouterOS data model
  routeros.ts        — RouterOS HTTP API client
```

**Build Outputs:**

```text
client/dist/         — Compiled VSCode extension
server/dist/         — Compiled LSP server
lsp-routeros-server* — Standalone binaries (various platforms)
*.vsix               — VSCode extension package
```

## Naming Conventions

Several identifiers are used across the project — each refers to a distinct scope:

- `lsp-routeros-ts` — the overall project; `-ts` denotes TypeScript implementation
- `lsp-routeros-server-*` — the standalone LSP server build artifacts
- `vscode-lsp-routeros` — the VSCode client package name (in `client/package.json`)
- `routeroslsp` — used wherever `-` is not allowed: settings prefix, npm package name (`@tikoci/routeroslsp`), NeoVim config key

## Implementation Overview

RouterOS LSP is built with [Microsoft's vscode-languageserver-node](https://github.com/microsoft/vscode-languageserver-node) and communicates with a running RouterOS device via its `/console/inspect` REST API. This means:

- Syntax definitions always match the connected RouterOS version
- New commands and attributes are available immediately after a RouterOS upgrade
- The LSP requires a live RouterOS device; it cannot work offline

### LSP Capabilities

| LSP Feature | Status |
|-------------|--------|
| Completion | ✅ Working |
| Semantic Tokens | ✅ Working |
| Diagnostics | ✅ Working |
| Hover | ⚠️ Basic (shows token type) |
| Document Symbols | ⚠️ Basic (variables only) |
| Execute Commands | ✅ Working (6 commands) |

For new LSP features, add handlers to `server/src/controller.ts`. Refer to the [LSP Protocol Specification](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/) for complete details.

### `/console/inspect` API

All syntax data comes from `POST /rest/console/inspect`. The `request` parameter controls what is returned:

| `request` | Returns | Used for |
|-----------|---------|----------|
| `highlight` | Token type per character (comma-separated) | Semantic tokens, diagnostics |
| `completion` | Completion items at cursor | Code completion |
| `syntax` | Command structure (dirs, cmds, args) | Not yet used |
| `child` | Child nodes of a path | Not yet used |

#### `request=syntax` examples

`request=syntax` is not currently used but may be useful for future features. Some notes on its behavior:

Adding a trailing space to `input` exposes arguments for a command:

```text
> /console/inspect request=syntax input="/ip/route add "
TYPE    SYMBOL               SYMBOL-TYPE  TEXT
syntax                       collection
syntax  blackhole            explanation
syntax  check-gateway        explanation  Whether all nexthops...
syntax  dst-address          explanation  Destination address
syntax  gateway              explanation
...
```

Adding a trailing `=` exposes value definitions:

```text
> /console/inspect request=syntax input="/ip/route add check-gateway="
TYPE    SYMBOL        SYMBOL-TYPE  TEXT
syntax  CheckGateway  definition
syntax                definition   arp | none | ping
```

For numeric types, `TEXT` shows the allowed range:

```text
> /console/inspect request=syntax input="/ip/service set port="
TYPE    SYMBOL  SYMBOL-TYPE  TEXT
syntax  Port    definition   Num
syntax  Num     definition   1..65535    (integer number)
```

The `TEXT` format varies significantly and would require parsing to be actionable in LSP — which is why `request=completion` is used instead for value lookups.

### Implementation Notes

**Position vs Offset:** The `vscode-languageserver` library uses line/character "position" in most APIs. For `/console/inspect`, a flat character "offset" is more useful. Use `TextDocument.offsetAt()` and `positionAt()` to convert between the two.

**Non-ASCII characters:** RouterOS uses Windows-1252 encoding. The LSP replaces any character with code > 127 with `?` before sending to `/console/inspect`, preserving character index alignment. The replacement only affects the query — file content is never modified.

**32KB document limit:** RouterOS API silently truncates large scripts. The LSP truncates at this boundary before querying.

## Testing

Tests use `bun test` with co-located `*.test.ts` files:

```bash
bun run test    # unit + snapshot tests (no device needed)
```

Integration tests against a live RouterOS device (CHR) are skipped automatically when no device is reachable. Set `ROUTEROS_TEST_URL` to override the default `http://192.168.74.150`. To regenerate snapshot files from a live device:

```bash
bun run server/src/capture-snapshots.ts
```

See [`BACKLOG.md`](BACKLOG.md) for remaining testing work.

### Forum Snippet Attribution

`test-data/forum/rextended/` contains scripts imported from this MikroTik forum page:

- https://forum.mikrotik.com/t/rextended-fragments-of-snippets/151033

Thanks to [@rextended](https://forum.mikrotik.com/u/rextended/summary) for sharing and maintaining these snippets.

To import snippets from a Discourse topic page (or refresh the same page), use:

```bash
bun run server/src/import-discourse-snippets.ts \
  --url 'https://forum.mikrotik.com/t/rextended-fragments-of-snippets/151033' \
  --author rextended \
  --out-dir test-data/forum/rextended
```

When `--url` is a root topic URL (`/t/.../<topicId>`), the importer fetches all posts in that topic.
When `--url` includes an explicit post number (`/t/.../<topicId>/<postNumber>`), only that Discourse window is imported.

Use `--include-blockquotes` for future imports where script text is embedded in block quotes instead of fenced code blocks.
Use `--follow-linked-pages` to crawl one level of topic links found on the seed page (no recursive crawling).

For local archive imports (for example `source_name=amm0` in `mcp-discourse`), use:

```bash
bun run server/src/import-discourse-sqlite-snippets.ts \
  --db-path /Users/amm0/Lab/mcp-discourse/discourse.sqlite \
  --source-name amm0 \
  --out-dir test-data/forum/amm0
```

This importer groups files under topic-based directories using topic IDs/titles from the database.
