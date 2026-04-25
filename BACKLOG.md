# RouterOS LSP — Backlog

> Active and planned work. Items marked ✅ are done, 🔄 in progress, 📋 planned, 💡 idea stage.
> See [`DESIGN.md`](DESIGN.md) for design rationale. See [`CLAUDE.md`](CLAUDE.md) for architecture.

## Working Order: Research Before Features

Several feature items below (especially under **LSP Feature Improvements**) are sketched from a thin slice of `/console/inspect` evidence and reasonable assumptions about how RouterOS represents scripts internally. Before extending core LSP logic further, we want a more complete empirical picture of RouterOS scripting so the next round of feature work isn't surprised by responses, encodings, or scopes that don't match our assumptions.

The triage rule for new work:

1. If a feature touches `controller.ts`/`model.ts`/`tokens.ts` and depends on RouterOS behavior we haven't measured against the corpus, it goes through **Research & Experiments** first — collect data, write up findings in [`DESIGN.md`](DESIGN.md), then build.
2. Items already grounded by snapshots, integration tests, or dataset assessment can proceed normally.
3. Spikes land harnesses in `scripts/` (not `server/src/`), throwaway probes in `.scratch/`, snapshots under `test-data/`, and conclusions in `DESIGN.md`.

Cross-references in feature sections use the tag `[research: <spike-id>]` to point at the blocking experiment.

## Pre-release Quality Gate

Goal: when a maintainer triggers a pre-release build, automated testing should give a strong signal that the extension works across **all six deployment contexts** — VSCode Desktop, VSCode Web, standalone binary, npm package (`@tikoci/routeroslsp`), NeoVim (via `nvim-routeros-lsp-init.lua`), and GitHub Copilot CLI (via `.github/lsp.json`). See [`deployment.instructions.md`](.github/instructions/deployment.instructions.md) for the matrix.

- 🔄 **Per-context smoke test in CI** — stdio smoke now covers the bundled Node server and standalone binary with a mocked RouterOS, running in `ci.yaml` on every push/PR (not just at release time). VSCode Desktop/Web, npm-installed bin, NeoVim, and Copilot CLI still need fuller per-context automation.
- 📋 **CI-booted CHR for integration** — run `integration.test.ts` against a QEMU CHR booted in GitHub Actions using [`tikoci/quickchr`](https://github.com/tikoci/quickchr). quickchr is specifically designed for this: pins a RouterOS version, exposes `/console/inspect` predictably, and runs headless. Pairs with the 📋 "QEMU CHR in CI" item under CI/CD below.
- 📋 **Pre-release checklist in `deployment.instructions.md`** — document what has to be green before `vsix:package:prerelease` is considered trustworthy. Keep it short enough that agents can actually follow it.
- 📋 **npm publish audit** — `@tikoci/routeroslsp` on npmjs.org is currently at 0.7.2 (`package.json` is at 0.7.3 as the next version). Confirm the conditional `if: env.NPM_TOKEN != ''` publish step actually runs on each pre-release, and that the shebang-prepend is correct. CI is the only supported publish path; no maintainer should `npm publish` from their laptop.
- 📋 **Copilot CLI LSP config still needs launch verification** — `.github/lsp.json` now uses obviously fake placeholders, but the `npx --yes @tikoci/routeroslsp --stdio` path still needs a real Copilot CLI smoke check after each npm publish. README now documents per-user override in `~/.copilot/lsp-config.json`.

## Research & Experiments (Pre-Feature Work)

Goal: ground the next round of LSP feature work in measured RouterOS behavior, using the 913-script corpus already in `test-data/` plus a [`tikoci/quickchr`](https://github.com/tikoci/quickchr)-booted CHR. Each spike produces (a) a reusable harness in `scripts/`, (b) snapshots/artifacts under `test-data/` (or a sibling dir), (c) a write-up in `DESIGN.md` answering specific questions. **Production code waits.**

### `[research: parseil]` Decode RouterOS `:parse` IL using the script corpus

✅ **Phases 1–3 complete (RouterOS 7.22.1).** Full reference: [`docs/parseil-format.md`](docs/parseil-format.md). Harness: `scripts/collect-parseil.ts`. Corpus snapshots: `test-data/**/*.v<routeros-version>.parseil` (912/913 captured against 7.22.1).

Headline findings worth surfacing in the BACKLOG (full detail in the reference doc):

- **Readout path:** only `:put [:parse $script]` reveals the IL — every other readout (`:tostr`, `:serialize`, `/environment print`, etc.) returns the literal placeholder `(code)`. Capture is `/rest/file/add` + `/rest/execute as-string=true`.
- **IL is text, not bytecode.** Forms: `(evl <PATH><ARGS>)` for command invocation (no whitespace between path and args — splitting them needs the command schema), `(<op> …)` for prefix-S-expr operators, `(<%% …)` for dynamic dispatch / function calls, `;` for statement separation, `/` for empty/comment-only scripts.
- **Parse-time canonicalisation is a goldmine.** `200ms` → `00:00:00.200`, `yes` → `true`, `:put` → `/put`, `/ip address print` → `/ip/address/print`. Excellent material for hover hints.
- **No source positions on valid IL.** `(line N column M)` only appears on errors; mapping IL nodes → source ranges still requires structural reconstruction.
- **`:parse` is a hard parser.** Stops at the first error, emits an error string with no partial IL. **Does not** back multi-error diagnostics — highlight remains the source of truth there.
- **Variable scope is by name.** No slot info; definition/references via IL alone requires walking the IL and reconstructing scopes from `(evl /local…)` / `(evl /global…)` / `do=` boundaries.
- **Parse is fast and has no 28 KB cliff.** Mean 9 ms across 912 scripts; max 1361 ms on a 56 KB script. Useful as a cheap pre-check for highlight.

Concrete feature work this unblocks (filed below under their respective sections):

- **Folding Ranges** off `do=;(evl …)` boundaries.
- **Document Symbols: functions** detection from `(evl /localdo=…;name=$f)`.
- **"Show parseIL" command + hover supplement** for canonicalised view.
- **`:parse` short-circuit before `highlight`** — skip a doomed highlight when parse already failed; surface line/col directly.
- **Definition / References (gated)** — feasible via IL scope reconstruction; not free.

**Open follow-ups (small):**

- 📋 Pin down the `(<%% …)` and `(> …)` semantics. Both leak into the RouterOS CLI as valid source-level syntax — `[(>[:put hello])]` evaluates to `hello` at the console — so they're real operators, not IL-internal markers. Working hypothesis: `(<%% …)` is "apply", `(>EXPR)` is "evaluate / dereference". Confirm via console probes (`:typeof (>[:put 1])` etc.) plus source-level examples from `mcp-discourse` once that data path is wired in. See [`docs/parseil-format.md`](docs/parseil-format.md) §3.5 + §8.
- 📋 Re-run `scripts/collect-parseil.ts` against newer CHR releases (7.22.2, 7.23rc, …) and diff `.v<version>.parseil` files to detect IL grammar drift.
- 📋 Measure the `/rest/file/add` upload cap; observed 413 at 126 KB, threshold unmeasured. Only matters if oversize scripts become a target.

### `[research: inspect-shapes]` Catalog `/console/inspect` request-type responses

We use `request=highlight` heavily, `request=completion` lightly, and have not characterized `syntax` or `child` against the corpus at all — yet feature items below assume their shape. Build a small harness in `scripts/inspect-catalog.ts` that, for a representative subset of `test-data/**/*.rsc` (and a fixed set of cursor positions per file), captures all four request types and saves them as `.inspect.<request>.json` snapshots. Document the schemas in `DESIGN.md` (one section per request type) so feature work can target the actual response shape, not what we remember from README. Pairs with the fake-space / fake-equals validation below.

### `[research: completion-tricks]` Validate fake-space / fake-equals heuristics across the corpus

The fake-space / fake-equals tricks are documented as folklore in README. Before wiring them into completion, run them through the corpus on a CHR: pick N positions from each script (start of token, mid-token, after `=`, after space), append the trick character, query `request=completion`, and record (a) when the trick yields strictly more results, (b) when it yields *different* (wrong) results, (c) when it errors. Output: a confidence table by context, and a recommendation on when each trick is safe to apply.

### `[research: 28kb]` Investigate the 28KB highlight inflection point

Profiling shows a sharp timing cliff at ~28KB across all syntax types. Spike: instrument the harness from `[research: inspect-shapes]` to sweep document size in 1KB increments around the cliff, vary syntax composition (pure comments, pure scripting, mixed), and try non-`highlight` request types to see if the cliff is endpoint-specific or process-wide. Goal: a write-up that's specific enough to file an upstream report at MikroTik, plus an LSP-side mitigation recommendation (truncate-with-warning vs split-and-stitch vs degrade-gracefully).

### `[research: rosetta-join]` Integrate `tikoci/rosetta` docs into hover / completion

[rosetta](https://github.com/tikoci/rosetta) exposes RouterOS docs as an FTS5 MCP server. Hover/completion could pull descriptions, examples, property tables, and changelog deltas from rosetta. Design questions worth answering before any code: does the LSP call rosetta directly (new dependency on the user having an MCP-capable client; doesn't work in VSCode Web), or do we expose a capability and let a Copilot/TikBook layer do the joining? How does this interact with `[research: inspect-shapes]`'s `request=syntax` data — overlap, complement, or redundant? Decision lives in `DESIGN.md` once scoped.

### `[research: md-embedded]` RouterOS in Markdown fenced blocks

Generalize the TikBook `.rsc.md` idea: any ` ```routeros ` fenced block inside any `.md` file should get semantic tokens, diagnostics, and completion. Requires range-mapping (document → fenced ranges → RouterOS highlight → back to document positions). Spike: prove out the offset-remapping in `.scratch/` against a hand-built `.md` fixture before deciding whether to do this in the LSP server or as a pre-processing step in the client.

## Quality & Infrastructure

### Testing
- ✅ **Update oversize integration test to use `oversize-32k.rsc`** — `integration.test.ts` now asserts `edge-cases/oversize-32k.rsc` exists and exercises truncation instead of silently no-oping against removed `export.rsc`.
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
- 📋 **Snapshot capture in CI** — run `scripts/capture-snapshots.ts` against CHR to regenerate `.highlight` files and detect regressions
- 🔄 **Smoke test tier** — stdio smoke tier launches the Node-bundled `server.js` and standalone binary, sends `initialize` + `textDocument/didOpen` + semantic tokens + diagnostics + completion, and verifies responses against a mocked RouterOS. Remaining: web target Worker shim and package-manager-installed npm bin smoke.

### CI/CD
- ✅ **Add lint to CI** — `build.yaml` now runs ESLint after compile
- ✅ **Add test step to CI** — `bun test` runs after compile in `build.yaml`
- ✅ **Add stdio smoke test step to CI** — `bun run test:smoke` runs after compile/unit tests and before publish/package steps
- ✅ **Make typecheck non-emitting** — `bun run lint` validates TypeScript without overwriting Bun-built `dist/` artifacts
- ✅ **Split CI from Release workflow** — `ci.yaml` runs compile/test/lint/smoke on every push to `main` and on PRs (no packaging, no publish). `build.yaml` stays `workflow_dispatch`-only for releases. Closes the gap where typecheck regressions could land on `main` and only surface at release time.
- 📋 **QEMU CHR in CI** — like restraml, boot CHR in GitHub Actions for integration tests
- 📋 **Automated VSIX publishing** — trigger publish on version tag

### Repository Structure
- ✅ **Move one-off scripts out of `server/src/`** — `assess-dataset.ts`, `profile-timing.ts`, `capture-snapshots.ts`, `import-discourse-snippets.ts`, and `import-discourse-sqlite-snippets.ts` moved to top-level `scripts/`. `server/src/` now contains only runtime code that ships in `dist/server.js`.
- ✅ **Move `*.test.ts` to `tests/`** — tests moved to `tests/server/` and `tests/client/` mirroring the source tree. `bunfig.toml`, `server/tsconfig.json`, `client/tsconfig.json` excludes all updated. `bun test tests/` is the new command. `tests/tsconfig.json` added with `paths` for `vscode-languageserver*` packages.
- ✅ **Use `.scratch/` for ad-hoc experiments** — `.scratch/` is gitignored. When agents want to try something without committing it (parsing experiments, API probes, etc.), land it there, not in `server/src/`.

### Code Quality
- ✅ **Split ambient auth from explicit execute auth** — read-only LSP traffic still uses ambient settings / TikBook overrides, while internal `router.validateScript` / `router.executeScript` commands require explicit per-call credentials and validate before execution
- ✅ **Fix typo: `onComletionHandler`** → `onCompletionHandler` (already correct in code, docs were wrong)
- ✅ **Fix typo: `inspectHighligh`** → `inspectHighlight` (routeros.ts, model.ts)
- ✅ **Add `variable-auto`, `obj-dynamic`, `obj-disabled` to TokenTypes** — dataset assessment (913 .rsc files) found variable-auto in 167 files, obj-dynamic in 4, obj-disabled in 2. Added to tokens.ts, package.json, theme, with tests.
- ✅ **Map raw RouterOS token aliases into semantic token types** — `arg-scope`, `arg-dot`, and `path` now map into the existing semantic legend, and dataset/integration checks use the same mapper as semantic token generation
- ✅ **Clean up duplicate `test-data/eworm-de/`** — merged into `test-data/eworm/`
- 📋 **Migrate ESLint to Biome** — align with user preference for single lint/format tool
- 📋 **Add `no-console` ESLint rule** — enforce `log.*` usage over `console.log`

## LSP Feature Improvements

### Completion
- 📋 **Use `request=syntax` for richer completions** — get descriptions, type info, value enums. *[research: inspect-shapes]*
- 📋 **Fake-space trick for arg completions** — append space to input for argument-level completions. *[research: completion-tricks]*
- 📋 **Fake-equals trick for value completions** — append `=` to get value definitions. *[research: completion-tricks]*
- 📋 **Completion item detail/documentation** — populate `CompletionItem.detail` and `documentation` from syntax TEXT. *[research: inspect-shapes, optionally rosetta-join]*
- 📋 **Make trigger characters configurable** — currently hardcoded `:=/ $[`

### Hover
- 📋 **Show command/argument descriptions** — use `request=syntax` TEXT field. *[research: inspect-shapes]*
- 📋 **Show type information** — detect `Num`, `IP`, enum types from syntax responses. *[research: inspect-shapes]*
- 📋 **Show value ranges** — parse "1..65535 (integer number)" format from syntax TEXT. *[research: inspect-shapes]*
- 📋 **Improve beyond debug info** — current hover shows token type regex, not user-friendly help. *[research: rosetta-join]*
- 📋 **"Show parseIL" hover supplement / command** — surface the `:parse` IL for the current script (or selection) as a debug view. *[research: parseil]*

### Diagnostics
- 📋 **Detect RouterOS data types** — flag type mismatches for `ip`, `num`, etc. *[research: inspect-shapes]*
- 📋 **Multi-error reporting** — currently stops at first error token. *[research: parseil]* — `:parse` reports multiple errors with line/col; may be a better source than `highlight` for this.
- 📋 **Severity levels** — differentiate errors, warnings (deprecated), info (old syntax)
- 📋 **Map `syntax-obsolete` to warnings** — flag deprecated commands

### New LSP Features
- 📋 **Signature Help** — show argument list and descriptions when typing commands. *[research: inspect-shapes]*
- 📋 **Code Actions** — suggest fixes for deprecated commands, old syntax
- 📋 **Formatting** — basic RouterOS script formatting
- 📋 **Folding Ranges** — fold blocks (`:if`, `:for`, `:foreach`, etc.). *[research: parseil]* — IL block delimiters are the natural source.
- 📋 **Definition/References** — variable scope tracking. *[research: parseil]* — gating question is whether the IL resolves `:local`/`:global` by name or slot.
- 📋 **Inlay Hints** — re-enable disabled `inlayHintProvider`; show type info inline. *[research: inspect-shapes]*
- 📋 **Code Lens** — show RouterOS path context above blocks
- 📋 **Document Links** — detect and link RouterOS paths (e.g., `/ip/firewall/filter`)
- 📋 **Document Symbols: functions, not just variables** — extract function definitions in addition to `:local`/`:global`. *[research: parseil]*

## VSCode Extension

### Commands
- 📋 **"Run on Router" command** — if/when a VSCode UI command is added, it should wrap the internal `router.validateScript` / `router.executeScript` commands and keep the explicit-credential policy
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
- 📋 **Mitigate the 28KB highlight cliff** — production-side fix (truncate-with-warning vs split-and-stitch vs degrade) once `[research: 28kb]` lands a recommendation.

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

- 📋 **TikBook: Semantic highlighting in `routeros` fenced blocks in `.rsc.md`** — parse `.rsc.md` files and apply RouterOS LSP semantic tokens inside ` ```routeros ` fenced code blocks. This should generalize to any `.md` file, not just TikBook notebooks — similar to embedded-language LSP features. Requires splitting the document into RouterOS ranges before querying `/console/inspect`, and remapping token offsets back to document positions. *[research: md-embedded]* covers the offset-remapping spike.
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
