# RouterOS LSP — Backlog

> Active and planned work. Items marked ✅ are done, 🔄 in progress, 📋 planned, 💡 idea stage.
> See [`DESIGN.md`](DESIGN.md) for design rationale. See [`CLAUDE.md`](CLAUDE.md) for architecture.

## Working Order: Research Before Features

Several feature items below (especially under **LSP Feature Improvements**) are sketched from a thin slice of `/console/inspect` evidence and reasonable assumptions about how RouterOS represents scripts internally. Before extending core LSP logic further, we want a more complete empirical picture of RouterOS scripting so the next round of feature work isn't surprised by responses, encodings, or scopes that don't match our assumptions.

The triage rule for new work:

1. If a feature touches `controller.ts`/`model.ts`/`tokens.ts` and depends on RouterOS behavior we haven't measured against the corpus, it goes through **Research & Experiments** first — collect data, write up findings in [`DESIGN.md`](DESIGN.md) or `docs/`, then build.
2. Items already grounded by snapshots, integration tests, or dataset assessment can proceed normally.
3. Spikes land harnesses in `scripts/` (not `server/src/`), throwaway probes in `.scratch/`, snapshots under `test-data/`, and conclusions in `DESIGN.md` or a dedicated `docs/` reference page.

Cross-references in feature sections use the tag `[research: <spike-id>]` to point at the blocking experiment.

## Pre-release Quality Gate

Goal: when a maintainer triggers a pre-release build, automated testing should give a strong signal that the extension works across **all six deployment contexts** — VSCode Desktop, VSCode Web, standalone binary, npm package (`@tikoci/routeroslsp`), NeoVim (via `nvim-routeros-lsp-init.lua`), and GitHub Copilot CLI (via `.github/lsp.json`). See [`deployment.instructions.md`](.github/instructions/deployment.instructions.md) for the matrix.

- 🔄 **Per-context smoke test in CI** — stdio smoke now covers the bundled Node server and standalone binary with a mocked RouterOS, running in `ci.yaml` on every push/PR (not just at release time). VSCode Desktop/Web, npm-installed bin, NeoVim, and Copilot CLI still need fuller per-context automation.
- 📋 **CI-booted CHR for integration** — run `integration.test.ts` against a QEMU CHR booted in GitHub Actions using [`tikoci/quickchr`](https://github.com/tikoci/quickchr). quickchr is specifically designed for this: pins a RouterOS version, exposes `/console/inspect` predictably, and runs headless. Pairs with the 📋 "QEMU CHR in CI" item under CI/CD below.
- ✅ **Pre-release checklist in `deployment.instructions.md`** — per-context checklist (VSCode Desktop/Web, standalone, npm, NeoVim, Copilot CLI) is in place; items graduate from manual to automated as CI coverage grows.
- 📋 **npm publish audit** — `@tikoci/routeroslsp` on npmjs.org is currently at 0.7.2 (`package.json` is at 0.7.3 as the next version). Confirm the conditional `if: env.NPM_TOKEN != ''` publish step actually runs on each pre-release, and that the shebang-prepend is correct. CI is the only supported publish path; no maintainer should `npm publish` from their laptop.
- 📋 **Copilot CLI LSP config still needs launch verification** — `.github/lsp.json` now uses obviously fake placeholders, but the `npx --yes @tikoci/routeroslsp --stdio` path still needs a real Copilot CLI smoke check after each npm publish. README now documents per-user override in `~/.copilot/lsp-config.json`.

## Research & Experiments (Pre-Feature Work)

Goal: ground the next round of LSP feature work in measured RouterOS behavior, using the 913-script corpus already in `test-data/` plus a [`tikoci/quickchr`](https://github.com/tikoci/quickchr)-booted CHR. Each spike produces (a) a reusable harness in `scripts/`, (b) normalized rows in `test-data/corpus.sqlite` (raw/export sidecars only when reviewable diffs are needed), (c) a write-up in `DESIGN.md` or a dedicated `docs/` reference page answering specific questions. **Production code waits.**

### Test corpus SQLite datastore

✅ **Initial framework complete.** `scripts/build-corpus-db.ts` rebuilds `test-data/corpus.sqlite` from committed scripts and sidecars, with FTS over source scripts, artifact provenance, parseIL/highlight imports, and normalized `required_arg_results` rows plus forward-compatible tables for `[research: inspect-shapes]` and `[research: completion-tricks]`. Future research harnesses should write normalized rows to the DB first and export JSON/Markdown only for human-review diffs or curated docs.

### `[research: parseil]` Decode RouterOS `:parse` IL using the script corpus

✅ **Phases 1–4 complete (RouterOS 7.20.8 / 7.22.1 / 7.23rc1).** Full reference: [`docs/parseil-format.md`](docs/parseil-format.md). Harness: `scripts/collect-parseil.ts`. Corpus snapshots: `test-data/**/*.v<routeros-version>.parseil` (912/913 captured on each version; the missed file is the intentional oversize upload-cap case).

Headline findings worth surfacing in the BACKLOG (full detail in the reference doc):

- **Readout path:** only `:put [:parse $script]` reveals the IL — every other readout (`:tostr`, `:serialize`, `/environment print`, etc.) returns the literal placeholder `(code)`. Capture is `/rest/file/add` + `/rest/execute as-string=true`.
- **IL is text, not bytecode.** Forms: `(evl <PATH><ARGS>)` for command invocation (no whitespace between path and args — splitting them needs the command schema), `(<op> …)` for prefix-S-expr operators, `(<%% …)` for "activate in environment" / function calls, `(> …)` for `op` quoting, `;` for statement separation, `/` for empty/comment-only scripts.
- **Parse-time canonicalisation is a goldmine.** `200ms` → `00:00:00.200`, `yes` → `true`, `:put` → `/put`, `/ip address print` → `/ip/address/print`. Excellent material for hover hints.
- **Core IL grammar looks stable through 7.23rc1.** 838/912 successful captures are byte-identical across 7.20.8, 7.22.1, and 7.23rc1. The 74 drifts are menu-schema, path-canonicalisation, and error-string churn — no new top-level IL forms showed up.
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

- ✅ Pin down the `(<%% …)` and `(> …)` semantics. `/console/inspect request=completion` labels `>` as `quote` and `<%%` as `activate in environment`; `:typeof (>[:put hello])` returns `op`; source-level forum examples use both directly. See [`docs/parseil-format.md`](docs/parseil-format.md) §3.5.
- ✅ Re-run `scripts/collect-parseil.ts` against 7.20.8 and 7.23rc1. Core IL forms stayed stable; observed drift is version-sensitive command schema/path/error churn, not a new grammar surface. See [`docs/parseil-format.md`](docs/parseil-format.md) §5.1.
- 📋 Measure the `/rest/file/add` upload cap; observed 413 at 126 KiB, threshold unmeasured. Only matters if oversize scripts become a target.

### `[research: required-args]` Build a version-tagged required-argument map

✅ **Complete (RouterOS 7.20.8 / 7.22.1 / 7.23rc1).** Full reference:
[`docs/required-args.md`](docs/required-args.md). Harness:
`scripts/collect-required-args.ts`. Artifacts:
`test-data/required-args.v<routeros-version>.json` +
`test-data/required-args.v<routeros-version>.meta.json`. Corpus DB import:
`required_arg_results`, `v_required_args_by_version`, `v_required_arg_drift`.

Headline findings worth surfacing here:

- **The execute-time signal is real and stable.** Exact `missing value(s) of argument(s) …` responses covered 146 paths on 7.20.8 and 149 paths on both 7.22.1 and 7.23rc1.
- **The add probe can be side-effect free.** `:local id [<menu> add]; :put $id; <menu> remove $id` cleanly distinguishes "missing args" from "no required args" without leaving junk rows behind.
- **Custom messages are usable but weaker.** 20/20/21 paths per version expose requirements only via human text (`certificate name must be set`, `address or mac-address is required`, `must specify exactly one of …`). The JSON export preserves `rawError`; `required[]` for those rows is a candidate-arg set, not a stronger structural signal than the text itself.
- **Only six existing paths drifted across the three versions.** `/interface/macsec/profile`, `/interface/wifi`, `/ip/dhcp-server/lease`, `/ipv6/pool`, `/routing/bgp/connection`, and `/system/package/local-update/update-package-source`.
- **For the menus that support `find where`, required-arg drift tracked `findwhere=` drift.** The live cross-check in [`docs/required-args.md`](docs/required-args.md#findwhere-cross-check) found no case where a required arg appeared/disappeared while the synthesized `findwhere=` field dump stayed unchanged.
- **A small unresolved tail remains.** Stateful/validation-heavy menus like `/interface/macvlan`, `/ip/dns/adlist`, `/ipv6/nd`, `/user/group`, plus a handful of RouterOS-support errors, need a second-stage probe or deliberate exclusion before shipping diagnostics.

**For the LSP:** The exact-pattern subset is already strong enough for an offline, version-tagged diagnostic map keyed by `{menuPath}/{version}`.

**Caveat — conditional args:** The single-pass `add` probe only reveals top-level requirements. Cases like `/disk add type=iscsi …` still need a discriminator-aware follow-up if we want full conditional-arg coverage.

### `[research: inspect-shapes]` Catalog `/console/inspect` request-type responses

We use `request=highlight` heavily, `request=completion` lightly, and have not characterized `syntax` or `child` against the corpus at all — yet feature items below assume their shape. Build a small harness in `scripts/inspect-catalog.ts` that, for a representative subset of `test-data/**/*.rsc` (and a fixed set of cursor positions per file), captures all four request types into normalized `inspect_responses` rows in `test-data/corpus.sqlite`. Store raw response JSON in the DB or `artifact_files`; export `.inspect.<request>.json` snapshots only when a reviewable diff is needed. Document the schemas in `DESIGN.md` (one section per request type) so feature work can target the actual response shape, not what we remember from README. Pairs with the fake-space / fake-equals validation below.

### `[research: completion-tricks]` Validate fake-space / fake-equals heuristics across the corpus

The fake-space / fake-equals tricks are documented as folklore in README. Before wiring them into completion, run them through the corpus on a CHR: pick N positions from each script (start of token, mid-token, after `=`, after space), append the trick character, query `request=completion`, and record normalized `completion_trick_results` rows in `test-data/corpus.sqlite`: (a) when the trick yields strictly more results, (b) when it yields *different* (wrong) results, (c) when it errors. Output only the summarized confidence table and recommendation on when each trick is safe to apply.

### `[research: 28kb]` Investigate the 28KB highlight inflection point

Profiling shows a sharp timing cliff at ~28KB across all syntax types. Spike: instrument the harness from `[research: inspect-shapes]` to sweep document size in 1KB increments around the cliff, vary syntax composition (pure comments, pure scripting, mixed), and try non-`highlight` request types to see if the cliff is endpoint-specific or process-wide. Goal: a write-up that's specific enough to file an upstream report at MikroTik, plus an LSP-side mitigation recommendation (truncate-with-warning vs split-and-stitch vs degrade-gracefully).

**parseil cross-check (from [`docs/parseil-format.md`](docs/parseil-format.md) §2):** `:parse` does not reproduce the cliff — a 56 KB script parsed cleanly in 1361 ms with no inflection point. This isolates the cliff to the `highlight` endpoint specifically (not a global RouterOS parse budget), which is useful evidence for the upstream report.

### `[research: rosetta-join]` Integrate `tikoci/rosetta` docs into hover / completion

**Research complete — see [`docs/rosetta-alignment.md`](docs/rosetta-alignment.md)** (third-eye refined 2026-04-25).

Key findings: no runtime dependency on rosetta. Two access models matter:
**Option A** (static JSON, ~6 KB gzipped) works in every deployment context including
VSCode Web; ship it first. **Option E** (lite DB + sql.js) gives richer hover content
in every context but requires rosetta to publish the lite DB artifact and the LSP to
adopt sql.js. Avoid `better-sqlite3` (per-platform native binaries in Marketplace VSIX
are a packaging headache). See § "The sqlite-in-VSCode problem" in the alignment doc.

Live device wins for syntax/structure/version-correctness; rosetta wins for prose,
URLs, and breaking-change history. See § "Online + offline — who wins for what".

Actionable items from the research:

- 📋 **`routeros-docs-links.json` artifact** — generate from rosetta DB (or the MCP server) and commit to `docs/`. **~6 KB gzipped** for 512 dirs. Used by hover and `textDocument/documentLink`. Filed upstream as [tikoci/rosetta#4](https://github.com/tikoci/rosetta/issues/4) so future updates can come from CI. *[rosetta-join P0]*
- 📋 **Hover doc link** — append `📚 [Documentation](url)` to hover output for `path` and `cmd-name` tokens using the above JSON. Simple `Map` lookup, no new runtime dep. *[rosetta-join P0]*
- 📋 **`textDocument/documentLink`** — new LSP capability: return a `DocumentLink` for every `path` token range, pointing at the docs URL. *[rosetta-join P0]*
- 📋 **Completion `documentation` field** — populate from `item.text` first (no rosetta needed), then optionally from `properties` table once Option E lands. *[rosetta-join P1]*
- 📋 **Lite DB + sql.js spike** — once rosetta ships `ros-help-lite.db` ([tikoci/rosetta#4](https://github.com/tikoci/rosetta/issues/4)), prove out a sql.js loader in `.scratch/` and measure WASM bundle impact on the Web target. Single code path for desktop + web. *[rosetta-join P2]*
- 📋 **Vendor `canonicalize.ts`** — pre-vendor audit at [`docs/canonicalize-audit.md`](docs/canonicalize-audit.md). **Safe fixes shipped upstream** in [tikoci/rosetta@9be870b](https://github.com/tikoci/rosetta/commit/9be870b) (BOM strip, backticks/ZWSP as whitespace, expanded universal verb set). Roadmap tracked at [tikoci/rosetta#5](https://github.com/tikoci/rosetta/issues/5) with the H1–H8 hardenings. **Vendoring no longer required** for routine extraction; reopen if/when we need the lenient prose-extraction mode (H1) or the pluggable `isVerb` resolver (H4 — needed for menu-specific verbs like `/log/info` that can't go in the universal set because `info` is also a dir at `/interface/wireless`). See § "Two backends, one parser" in the audit doc for the alignment between rosetta's DB-backed resolver and the LSP's live-inspect path. *[rosetta-join P2]*
- 📋 **Upstream rosetta asks** — `routeros-docs-links.json` CI export ([#4](https://github.com/tikoci/rosetta/issues/4) ✅ filed), `ros-toc.json` cleanup ([#3](https://github.com/tikoci/rosetta/issues/3) ✅ filed), lite DB CI artifact, `command_path` column on `properties`, `routeros_lookup_path` MCP tool, ship `schema_nodes` to released DB. *[rosetta-join P3]*

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
- ✅ **Corpus SQLite datastore** — `scripts/build-corpus-db.ts` rebuilds `test-data/corpus.sqlite` from scripts and sidecars; future research spikes store normalized data there instead of scattering one-off JSON/Markdown sidecars.
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
- ✅ **Migrate ESLint to Biome** — `biome.json` in place; `bun run lint` now runs `bunx @biomejs/biome lint` over `server/src/` and `client/src/`. ESLint removed.
- ✅ **Add Biome `noConsole` rule** — `suspicious.noConsole: "error"` added to `biome.json`; removed pre-connection `console.*` debug traces from `server.web.ts` and both client entry points.

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
- 📋 **"Show parseIL" hover supplement / command** — surface the `:parse` IL for the current script (or selection) as a debug view. The capture pattern (file upload → `:put [:parse …]` via `/rest/execute`) is fully documented in [`docs/parseil-format.md`](docs/parseil-format.md) §2; grammar reference in §3. *[research: parseil]*

### Diagnostics
- 📋 **Detect RouterOS data types** — flag type mismatches for `ip`, `num`, etc. *[research: inspect-shapes]*
- 📋 **Multi-error reporting** — currently stops at first error token. `highlight` is the only viable source for multi-error diagnostics: it marks every error token and continues. `:parse` is a **hard parser** — it stops at the first error with no partial IL — so parseIL cannot back multi-error reporting (confirmed by [`docs/parseil-format.md`](docs/parseil-format.md) §4). *[research: inspect-shapes]*
- 📋 **Severity levels** — differentiate errors, warnings (deprecated), info (old syntax)
- 📋 **Map `syntax-obsolete` to warnings** — flag deprecated commands

### New LSP Features
- 📋 **Signature Help** — show argument list and descriptions when typing commands. *[research: inspect-shapes]*
- 📋 **Code Actions** — suggest fixes for deprecated commands, old syntax
- 📋 **Formatting** — basic RouterOS script formatting
- 📋 **Folding Ranges** — fold blocks (`:if`, `:for`, `:foreach`, etc.). IL block delimiters (`do=;`, `else=;`, `on-error=;` followed by sibling `(evl …)`) are the natural source. See [`docs/parseil-format.md`](docs/parseil-format.md) §3.3 for the block-body IL pattern. *[research: parseil]*
- 📋 **Definition/References** — variable scope tracking via IL scope reconstruction. The gating question (name vs slot) is now answered: **IL resolves by name, not slot** — there is no syntactic distinction between `:local`-bound, `:global`-bound, parameter, and built-in `$1`/`$2` refs (see [`docs/parseil-format.md`](docs/parseil-format.md) §3.6). Scopes must be reconstructed by walking `(evl /local…)` / `(evl /global…)` / `do=` boundaries. Feasible but not free. *[research: parseil]*
- 📋 **Inlay Hints** — re-enable disabled `inlayHintProvider`; show type info inline. *[research: inspect-shapes]*
- 📋 **Code Lens** — show RouterOS path context above blocks
- 📋 **Document Links** — detect and link RouterOS paths (e.g., `/ip/firewall/filter`)
- 📋 **Document Symbols: functions, not just variables** — extract function definitions in addition to `:local`/`:global`. Functions lower to `(evl /localdo=;…;name=$f)` in the IL; the `do=` key with a non-empty body distinguishes them from plain variable declarations. See [`docs/parseil-format.md`](docs/parseil-format.md) §3.5 (`<%%` and function-call IL). *[research: parseil]*

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
- 📋 **RouterOS API reference** — document all `/console/inspect` request types and response formats used. Note: [`docs/parseil-format.md`](docs/parseil-format.md) already covers the `:parse` / IL endpoint in full; the remaining `request=highlight`, `request=completion`, and `request=syntax` shapes belong to `[research: inspect-shapes]`.

## Architecture & Internals

### Performance
- 📋 **Incremental document sync** — switch from full-document to incremental sync
- 📋 **Debounce/throttle API calls** — avoid flooding RouterOS on rapid typing; profiling shows 32KB scripts take 2–6 seconds depending on syntax complexity
- 📋 **Request cancellation** — cancel in-flight requests when document changes again
- 📋 **Mitigate the 28KB highlight cliff** — production-side fix (truncate-with-warning vs split-and-stitch vs degrade) once `[research: 28kb]` lands a recommendation. Note: [`docs/parseil-format.md`](docs/parseil-format.md) §2 confirms `:parse` does not share the cliff (56 KB parsed cleanly), so the issue is specific to the `highlight` endpoint.

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
