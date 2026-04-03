# RouterOS LSP — Backlog

> Active and planned work. Items marked ✅ are done, 🔄 in progress, 📋 planned, 💡 idea stage.
> See [`DESIGN.md`](DESIGN.md) for design rationale. See [`CLAUDE.md`](CLAUDE.md) for architecture.

## Quality & Infrastructure

### Testing
- ✅ **Set up `bun test` runner** — configured with `bunfig.toml` preload for log silencing
- ✅ **Anchor tests for tokens.ts** — `HighlightTokens` parsing, `tokenRanges`, `atPosition`, `regexToken`
- ✅ **Anchor tests for routeros.ts** — `replaceNonAscii`, `normalizeError`
- ✅ **Anchor tests for shared.ts** — settings, `updateSettings`, `getConnectionUrl`, `useConnectionUrl`
- ✅ **Anchor tests for controller.ts** — `shortid`, `getServerCapabilities`, `hasCapability`
- ✅ **Anchor tests for model.ts** — `LspDocument.diagnostics()` with mocked `RouterRestClient`
- ✅ **Snapshot tests for tokens** — parses `.rsc.highlight` snapshot files offline (dynamic per snapshot pair)
- ✅ **Watchdog error mapping tests** — `toErrorInfo`/`getTextFromError` (extracted to `watchdog-errors.ts`)
- ✅ **Integration tests with QEMU CHR** — `inspectHighlight` for all `test-data/**/*.rsc` against live CHR (auto-skips when no CHR)
- ✅ **Test data catalog** — `test-data/` expanded with eworm, forum, edge-case scripts + snapshot `.highlight` files
- 📋 **VSCode integration tests** — boot real VS Code with `@vscode/test-electron`, install VSIX, verify semantic tokens, diagnostics, and completion work end-to-end
- 📋 **Snapshot capture in CI** — run `capture-snapshots.ts` against CHR to regenerate `.highlight` files and detect regressions

### CI/CD
- ✅ **Add lint to CI** — `build.yaml` now runs ESLint after compile
- ✅ **Add test step to CI** — `bun test` runs after compile in `build.yaml`
- 📋 **QEMU CHR in CI** — like restraml, boot CHR in GitHub Actions for integration tests
- 📋 **Automated VSIX publishing** — trigger publish on version tag

### Code Quality
- ✅ **Fix typo: `onComletionHandler`** → `onCompletionHandler` (already correct in code, docs were wrong)
- ✅ **Fix typo: `inspectHighligh`** → `inspectHighlight` (routeros.ts, model.ts)
- 📋 **Add `arg-scope` and `arg-dot` to TokenTypes** — snapshot tests revealed RouterOS returns these token types but they're not in `HighlightTokens.TokenTypes`; currently mapped to `?` in regexToken
- ✅ **Clean up duplicate `test-data/eworm-de/`** — merged into `test-data/eworm/`
- 📋 **Migrate ESLint to Biome** — align with user preference for single lint/format tool
- 📋 **Add `no-console` ESLint rule** — enforce `log.*` usage over `console.log`

## LSP Feature Improvements

### Completion
- 📋 **Use `request=syntax` for richer completions** — get descriptions, type info, value enums
- 📋 **Fake-space trick for arg completions** — append space to input for argument-level completions
- 📋 **Fake-equals trick for value completions** — append `=` to get value definitions
- 📋 **Completion item detail/documentation** — populate `CompletionItem.detail` and `documentation` from syntax TEXT
- 📋 **Make trigger characters configurable** — currently hardcoded `:=/ $[`

### Hover
- 📋 **Show command/argument descriptions** — use `request=syntax` TEXT field
- 📋 **Show type information** — detect `Num`, `IP`, enum types from syntax responses
- 📋 **Show value ranges** — parse "1..65535 (integer number)" format from syntax TEXT
- 📋 **Improve beyond debug info** — current hover shows token type regex, not user-friendly help

### Diagnostics
- 📋 **Detect RouterOS data types** — flag type mismatches for `ip`, `num`, etc.
- 📋 **Multi-error reporting** — currently stops at first error token
- 📋 **Severity levels** — differentiate errors, warnings (deprecated), info (old syntax)
- 📋 **Map `syntax-obsolete` to warnings** — flag deprecated commands

### New LSP Features
- 📋 **Signature Help** — show argument list and descriptions when typing commands
- 📋 **Code Actions** — suggest fixes for deprecated commands, old syntax
- 📋 **Formatting** — basic RouterOS script formatting
- 📋 **Folding Ranges** — fold blocks (`:if`, `:for`, `:foreach`, etc.)
- 📋 **Definition/References** — variable scope tracking (complex; requires parsing `:local`/`:global`)
- 📋 **Inlay Hints** — re-enable disabled `inlayHintProvider`; show type info inline
- 📋 **Code Lens** — show RouterOS path context above blocks
- 📋 **Document Links** — detect and link RouterOS paths (e.g., `/ip/firewall/filter`)

## VSCode Extension

### Commands
- 📋 **"Run on Router" command** — execute selected code on connected RouterOS
- 📋 **"Show RouterOS Version" command** — display connected device version info
- 📋 **"Export Config" command** — fetch and display running config sections
- 📋 **Copilot integration helpers** — expose RouterOS context for AI assistants

### UX
- 📋 **Improve walkthrough** — `docs/walkthrough.md` is placeholder; add graphics, screenshots
- 📋 **Better error notifications** — enhance watchdog messages with more context
- 📋 **Status bar indicator** — show connection state and RouterOS version
- 📋 **Snippet support** — common RouterOS script patterns

## NeoVim / Standalone

- ✅ **Fix/verify NeoVim init script** — updated `nvim-routeros-lsp-init.lua` for NeoVim 0.10+: removed deprecated `buf_attach_client`/`on_init` pattern, fixed `vim.highlight`→`vim.hl`, guarded `vim.lsp.completion` (0.11+), improved `root_dir` detection
- ✅ **Document lazy.nvim setup** — added lazy.nvim snippet to README; npm install path removes quarantine friction
- ✅ **Publish npm package** — `@tikoci/routeroslsp` with `routeroslsp-langserver` bin; reduces NeoVim install to 4 steps with no platform binary selection
- 📋 **lspconfig entry** — contribute to nvim-lspconfig for official NeoVim LSP registry
- ✅ **Windows arm64 in CI** — added to `build.yaml` build loop (was disabled; user reports compiles now)
- 📋 **Socket transport testing** — `--socket=<port>` is experimental, needs validation

## Documentation

- 📋 **User manual** — comprehensive guide beyond README.md (topics: setup, troubleshooting, features, customization)
- 📋 **CORS proxy guide** — expand `docs/cors.md` with actual instructions (Caddy, nginx, Cloudflare Tunnel)
- 📋 **Developer guide** — document how to add new LSP features (controller handler patterns)
- 📋 **RouterOS API reference** — document all `/console/inspect` request types and response formats used

## Architecture & Internals

### Performance
- 📋 **Incremental document sync** — switch from full-document to incremental sync
- 📋 **Debounce/throttle API calls** — avoid flooding RouterOS on rapid typing
- 📋 **Request cancellation** — cancel in-flight requests when document changes again

### Code Organization
- 📋 **Extract completion logic** — `controller.ts` at ~850 lines is getting large
- 📋 **Separate command handlers** — move `onExecuteCommand` cases to individual handlers
- 📋 **Type RouterOS API responses** — add TypeScript interfaces for all API response shapes

### Web Target
- 📋 **CORS proxy documentation** — make VSCode Web actually usable
- 📋 **Test web extension regularly** — currently "should work but untested"
- 📋 **Consider bundled CORS proxy** — could ship a simple proxy as part of the extension

## Cross-Extension Integration

- 📋 **TikBook: Move cell execution to LSP** — currently in TikBook, should be LSP feature
- 📋 **TikBook: LSP-based notebook diagnostics** — use LSP diagnostics for notebook cells
- 📋 **restraml: Validate configs against schema** — use RAML/OpenAPI schemas for deeper validation
- 📋 **QEMU CHR management** — embed or integrate with TikBook's CHR VM features for quick version switching

## Ideas (Exploratory)

- 💡 **Offline mode with cached syntax** — cache last-known syntax data for limited offline editing
- 💡 **Multi-router support** — switch between different RouterOS versions/devices
- 💡 **RouterOS terminal integration** — embedded SSH/terminal in VSCode for live router interaction
- 💡 **Copilot Chat participant** — RouterOS domain expert for `@routeros` mentions
- 💡 **WebMCP tool for LSP** — expose LSP capabilities as MCP tools for AI agents
