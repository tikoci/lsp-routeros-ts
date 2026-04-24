# RouterOS LSP — Backlog

> Active and planned work. Items marked ✅ are done, 🔄 in progress, 📋 planned, 💡 idea stage.
> See [`DESIGN.md`](DESIGN.md) for design rationale. See [`CLAUDE.md`](CLAUDE.md) for architecture.

## Pre-release Quality Gate

Goal: when a maintainer triggers a pre-release build, automated testing should give a strong signal that the extension works across **all six deployment contexts** — VSCode Desktop, VSCode Web, standalone binary, npm package (`@tikoci/routeroslsp`), NeoVim (via `nvim-routeros-lsp-init.lua`), and GitHub Copilot CLI (via `.github/lsp.json`). See [`deployment.instructions.md`](.github/instructions/deployment.instructions.md) for the matrix.

- 📋 **Per-context smoke test in CI** — for each deployment context, a minimal "LSP handshake + one `highlight` request" check. Must be cheap enough to run on every pre-release build.
- 📋 **CI-booted CHR for integration** — run `integration.test.ts` against a QEMU CHR booted in GitHub Actions using [`tikoci/quickchr`](https://github.com/tikoci/quickchr). quickchr is specifically designed for this: pins a RouterOS version, exposes `/console/inspect` predictably, and runs headless. Pairs with the 📋 "QEMU CHR in CI" item under CI/CD below.
- 📋 **Pre-release checklist in `deployment.instructions.md`** — document what has to be green before `vsix:package:prerelease` is considered trustworthy. Keep it short enough that agents can actually follow it.
- 📋 **npm publish audit** — `@tikoci/routeroslsp` on npmjs.org is currently at 0.7.2 (`package.json` is at 0.7.3 as the next version). Confirm the conditional `if: env.NPM_TOKEN != ''` publish step actually runs on each pre-release, and that the shebang-prepend is correct. CI is the only supported publish path; no maintainer should `npm publish` from their laptop.
- 📋 **Copilot CLI LSP config is currently broken** — `.github/lsp.json` uses `npx --yes @tikoci/routeroslsp --stdio`, which depends on the npm package being in sync. It also ships with placeholder credentials that look real (`routeros-user`/`routeros-password`). Needs: (a) verification the command line actually launches the server under Copilot CLI, (b) clearer placeholders, (c) a README note on how to override per-user in `~/.copilot/lsp-config.json` without committing credentials.

## Quality & Infrastructure

### Testing
- 📋 **Update oversize integration test to use `oversize-32k.rsc`** — `export.rsc` was removed from test-data root; the `export.rsc — oversize file handling` describe in `integration.test.ts` now silently no-ops (`if (!exportFile) return`). Should be updated to find `edge-cases/oversize-32k.rsc` instead.
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
- ✅ **Dataset assessment tool** — `assess-dataset.ts` runs all 913 .rsc files through CHR highlight API; measures timing, token quality, unknown types, data signals. Results: 912/913 OK, median 7ms, avg 30ms, max 3822ms.
- ✅ **Performance profiling tool** — `profile-timing.ts` tests size→time relationship with progressive truncation + synthetic controls. Confirmed superlinear (quadratic) scaling across all syntax types, with a sharp inflection at ~28KB. Scripting syntax (variables, functions, control flow) costs 3× more than comments at the same size.
- 📋 **VSCode integration tests** — boot real VS Code with `@vscode/test-electron`, install VSIX, verify semantic tokens, diagnostics, and completion work end-to-end
- 📋 **Snapshot capture in CI** — run `capture-snapshots.ts` against CHR to regenerate `.highlight` files and detect regressions
- 📋 **Smoke test tier** — new tier between unit and integration: launches the server process (stdio), sends `initialize` + one `textDocument/didOpen` + one `textDocument/semanticTokens/full`, verifies a non-empty response. Runs against a mocked RouterOS so it needs no CHR; separate from unit tests so a smoke failure is a clear "the transport/protocol layer broke" signal. Run for both the Node-bundled `server.js` and the standalone binary; web target uses a Worker shim.

### CI/CD
- ✅ **Add lint to CI** — `build.yaml` now runs ESLint after compile
- ✅ **Add test step to CI** — `bun test` runs after compile in `build.yaml`
- 📋 **QEMU CHR in CI** — like restraml, boot CHR in GitHub Actions for integration tests
- 📋 **Automated VSIX publishing** — trigger publish on version tag

### Repository Structure
- 📋 **Move one-off scripts out of `server/src/`** — `assess-dataset.ts`, `profile-timing.ts`, `capture-snapshots.ts`, `import-discourse-snippets.ts`, and `import-discourse-sqlite-snippets.ts` are tooling, not LSP runtime code. They should live in a top-level `scripts/` directory so `server/src/` stays "only what ships in `dist/server.js`". Rationale: agents keep dumping new experimentation scripts next to runtime code because there's no other obvious home — exactly how the current clutter accumulated. `server/tsconfig.json` already has to exclude them from compilation.
- 📋 **Move `*.test.ts` to `tests/`** — tests are co-located today; the user-stated preference is that `client/src/` and `server/src/` hold runtime code only. Consider `tests/server/*.test.ts` mirroring source layout, or `server/tests/*.test.ts`. Adjust `bunfig.toml`, `server/tsconfig.json` excludes, and the `test` script in `package.json`. Do as a single focused PR — don't mix with feature work.
- 📋 **Use `.scratch/` for ad-hoc experiments** — `.scratch/` is already gitignored. When agents want to try something without committing it (parsing experiments, API probes, etc.), land it there, not in `server/src/`.

### Code Quality
- ✅ **Fix typo: `onComletionHandler`** → `onCompletionHandler` (already correct in code, docs were wrong)
- ✅ **Fix typo: `inspectHighligh`** → `inspectHighlight` (routeros.ts, model.ts)
- ✅ **Add `variable-auto`, `obj-dynamic`, `obj-disabled` to TokenTypes** — dataset assessment (913 .rsc files) found variable-auto in 167 files, obj-dynamic in 4, obj-disabled in 2. Added to tokens.ts, package.json, theme, with tests.
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
- 📋 **Cross-project AI tool exposure alignment** — decide how TikBook, RouterOS LSP, and Rosetta divide responsibility for agent-facing RouterOS tools (`languageModelTools`, MCP, chat participants, etc.). Keep RouterOS LSP focused on pure LSP behavior until the shared design is settled.

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
- 📋 **Debounce/throttle API calls** — avoid flooding RouterOS on rapid typing; profiling shows 32KB scripts take 2–6 seconds depending on syntax complexity
- 📋 **Request cancellation** — cancel in-flight requests when document changes again
- 📋 **Investigate 28KB inflection point** — profiling shows a sharp timing step at ~28KB for all syntax types (e.g., comments jump from 330ms at 24KB to 1494ms at 28KB). This may be a RouterOS internal buffer boundary worth reporting upstream.

### Code Organization
- 📋 **Extract completion logic** — `controller.ts` at ~850 lines is getting large
- 📋 **Separate command handlers** — move `onExecuteCommand` cases to individual handlers
- 📋 **Type RouterOS API responses** — add TypeScript interfaces for all API response shapes

### Web Target
- 📋 **CORS proxy documentation** — make VSCode Web actually usable
- 📋 **Test web extension regularly** — currently "should work but untested"
- 📋 **Consider bundled CORS proxy** — could ship a simple proxy as part of the extension

## Cross-Extension Integration

### TikBook Notebook Format Support

TikBook uses two notebook formats. Example files for both are in `test-data/tikbook/`.

**RouterOS-first** (`.tikbook.rsc`): `#!tikbook` shebang at top; `#.` separates cells; `#.markdown` starts a markdown cell; RouterOS comments (`# text`) used for inline prose.

**Markdown-first** (`.tikbook.rsc.md` / `.rsc.md`): `[//]: #!tikbook` marker at top; ` ```routeros ` fenced code blocks are executable cells; regular Markdown for prose between cells.

- 📋 **TikBook: Semantic highlighting in `routeros` fenced blocks in `.rsc.md`** — parse `.rsc.md` files and apply RouterOS LSP semantic tokens inside ` ```routeros ` fenced code blocks. This should generalize to any `.md` file, not just TikBook notebooks — similar to embedded-language LSP features. Requires splitting the document into RouterOS ranges before querying `/console/inspect`, and remapping token offsets back to document positions.
- 📋 **TikBook: Move cell execution to LSP** — currently in TikBook, should be LSP feature
- 📋 **TikBook: LSP-based notebook diagnostics** — use LSP diagnostics for notebook cells
- 📋 **restraml: Validate configs against schema** — use RAML/OpenAPI schemas for deeper validation
- 📋 **QEMU CHR management** — embed or integrate with TikBook's CHR VM features for quick version switching

## Research Spikes

- 📋 **`[:parse <script>]` IL inspection** — RouterOS's `:parse` returns a `code`-typed internal representation (stack-based IL) of a transpiled script. Questions worth answering with a spike: (a) is parse time predictive of highlight time — i.e. could the LSP short-circuit expensive highlight requests when `:parse` returns fast? (b) does the IL expose block structure / scope info that could back folding ranges, definition/references, or more accurate diagnostics? (c) is it a useful debug surface for agents authoring RouterOS scripts? Land as a throwaway script in `.scratch/` first, write up findings in `DESIGN.md` before any production code.
- 📋 **Integrate `tikoci/rosetta` docs** — rosetta exposes RouterOS docs as an FTS5 MCP server. Hover/completion could pull descriptions, examples, property tables, and changelog deltas from rosetta. Design question: does the LSP call rosetta directly (new dependency), or do we expose a capability and let a Copilot/TikBook layer do the joining? Decision lives in DESIGN.md once scoped.
- 📋 **RouterOS in Markdown fenced blocks** — generalize the TikBook `.rsc.md` idea: any ` ```routeros ` fenced block inside any `.md` file should get semantic tokens, diagnostics, and completion. Requires range-mapping (document → fenced ranges → RouterOS highlight → back to document positions). Captured previously under TikBook; promoted to a first-class research spike because its scope is broader.

## Ideas (Exploratory)

- 💡 **Offline mode with cached syntax** — cache last-known syntax data for limited offline editing
- 💡 **Multi-router support** — switch between different RouterOS versions/devices
- 💡 **RouterOS terminal integration** — embedded SSH/terminal in VSCode for live router interaction
- 💡 **Copilot Chat participant** — RouterOS domain expert for `@routeros` mentions
- 💡 **WebMCP tool for LSP** — expose LSP capabilities as MCP tools for AI agents
