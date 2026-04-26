---
applyTo: "**/*.test.ts,test-data/**,bunfig.toml,**/test-preload.ts,scripts/**,.scratch/**"
description: "Use when writing or modifying tests or tooling scripts. Covers test tiers (unit, model, snapshot, smoke, integration), anchor testing pattern, snapshot workflow, CHR integration via quickchr, and where scripts vs. tests vs. experiments belong."
---

# Testing Guidelines

## Test vs. Script vs. Scratch

The user's expectation is that `client/src/` and `server/src/` hold **runtime code only** — what ships in `dist/`. Three other buckets:

| Kind | Lives in | Example | Notes |
|------|----------|---------|-------|
| Test | `tests/server/` or `tests/client/` | `tokens.test.ts` | Deterministic, runs under `bun test`. Anchor tests preferred. |
| Tooling script | `scripts/` | `capture-snapshots.ts`, `profile-timing.ts`, `assess-dataset.ts`, `import-discourse-*.ts` | Run by hand or from CI; not shipped. |
| Experiment | `.scratch/` (gitignored) | `routeros2.js`, `parse-il-probe.ts` | For one-off probes and throwaway validation. If it survives, promote it into a script or test. |

**Do not add new tests or one-off scripts to `server/src/` or `client/src/`.**

## Test Runner & Config

- `bun test tests/` runs all tests (~3866 tests, <600ms without CHR).
- `bunfig.toml` preloads `tests/test-preload.ts` to silence `log.*` output
- Test files live in `tests/server/` (server tests) and `tests/client/` (client tests)
- `server/tsconfig.json` and `client/tsconfig.json` compile only runtime code — tests have their own `tests/tsconfig.json`

## Test Tiers

### Unit tests (no dependencies)
- `tokens.test.ts` — `HighlightTokens` parsing, `tokenRanges`, `atPosition`, `regexToken`
- `routeros.test.ts` — `replaceNonAscii`, `normalizeError`
- `shared.test.ts` — settings CRUD, `getConnectionUrl`, `useConnectionUrl`/`clearConnectionUrl`
- `controller.test.ts` — `getServerCapabilities`, `hasCapability`, `shortid`

### Model tests (mocked HTTP)
- `model.test.ts` — `LspDocument.diagnostics()` with mocked `RouterRestClient.default.inspectHighlight`
- Covers: clean scripts, error tokens, unchecked region warnings, 32KB truncation

### Snapshot tests (offline, uses .highlight files)
- `snapshot.test.ts` — parses `.rsc.highlight` files alongside `.rsc` scripts
- Validates: token count matches char count, all types known, contiguous ranges, regexToken length
- Generate snapshots: `bun run scripts/capture-snapshots.ts` (requires live CHR)

### Client tests (no VSCode dependency)
- `watchdog-errors.test.ts` — tests `toErrorInfo` and `getTextFromError` from `watchdog-errors.ts`
- These are pure functions extracted from `watchdog.ts` to avoid VSCode import issues

### Smoke tests (`tests/smoke/stdio-smoke.ts`)
- Goal: per deployment context, verify the LSP boots and responds to `initialize`, `textDocument/didOpen`, semantic tokens, diagnostics, and completion end-to-end against a mocked RouterOS HTTP server. Catches transport/packaging regressions unit tests cannot.
- Currently covers two stdio contexts: the Node-bundled `server/dist/server.js` and the standalone `bun build --compile` binary. Run via `bun run test:smoke` (also runs in `ci.yaml` on every push/PR and in `build.yaml` before release).
- Uses a mock RouterOS over `http://127.0.0.1:<random-port>` — smoke tests must not depend on a live CHR. Integration tests cover the CHR side.
- **Path resolution**: file/spawn paths are resolved against the module-derived repo root (`fileURLToPath(new URL('.', import.meta.url))` → `../..`), not the runtime cwd. If you add new targets or path checks, follow the same pattern so the harness can be invoked from any cwd.
- **TS types around `Buffer.concat`**: keep the `Uint8Array.from()` wrapping. Under TS 5.7+ with current `@types/node`, `Buffer.alloc(0)` is `Buffer<ArrayBuffer>` while `Buffer.concat(Buffer[])` returns `Buffer<ArrayBufferLike>` — the assignment fails strict typecheck. The wrapping is a deliberate coercion, not dead code; CodeQL has flagged it as "unnecessary" before.
- Remaining contexts to add: web bundle (via a Worker shim), npm-installed bin (`npx --yes @tikoci/routeroslsp --stdio` from a clean node_modules). See [`deployment.instructions.md`](deployment.instructions.md#pre-release-checklist).

### Integration tests (requires live CHR)
- `integration.test.ts` — connects to CHR, sends all `test-data/**/*.rsc` through `inspectHighlight`
- Auto-skips when CHR is unreachable
- Override CHR address: `ROUTEROS_TEST_URL=http://... bun test tests/server/integration.test.ts`
- **In CI, prefer [`tikoci/quickchr`](https://github.com/tikoci/quickchr)** to boot a version-pinned CHR. quickchr is the designated QEMU expert project in the tikoci stack; it handles version selection, boot-wait loops, and port forwarding so that a GitHub Actions runner gets a predictable `/console/inspect`. See 📋 "QEMU CHR in CI" in BACKLOG.

## Assessment & Profiling Tools (not tests — standalone scripts)

### Dataset assessment (`assess-dataset.ts`)
- Runs all `test-data/**/*.rsc` files through CHR highlight API
- Reports: timing, token quality, unknown types, error tokens, CLI prompts, data signals
- Usage: `bun run scripts/assess-dataset.ts [--json] [--concurrency=N]`
- JSON output: `test-data/assessment-results.json` (gitignored)

### Corpus datastore (`build-corpus-db.ts`)
- Rebuilds the checked-in SQLite corpus database at `test-data/corpus.sqlite` from committed `.rsc` files and sidecars
- Imports script metadata, FTS text, `.rsc.highlight` snapshots, parseIL `.parseil`/`.parseil.meta.json` captures, artifact provenance, and forward-compatible tables for inspect-shapes/completion-tricks research
- Usage: `bun run corpus:db` or `bun run scripts/build-corpus-db.ts [--db test-data/corpus.sqlite]`
- Because `corpus.sqlite` is checked in, rebuilds must be deterministic from committed inputs; prefer corpus fingerprints and source capture timestamps over wall-clock import timestamps
- Future research harnesses should write normalized rows to this DB first; export JSON/Markdown only when a reviewer needs a textual diff or docs need a curated excerpt

### Performance profiling (`profile-timing.ts`)
- Tests size→time relationship by truncating scripts at progressive sizes (128B → 32KB)
- Includes synthetic controls (pure comments, simple commands, complex scripting, mixed paths)
- Also profiles real files (eworm/global-functions.rsc, oversize-32k.rsc, complex/piano.rsc)
- Usage: `bun run scripts/profile-timing.ts`
- Key finding: superlinear (quadratic) scaling; sharp inflection at ~28KB; scripting syntax costs ~3× more than comments

## Test Strategy: Anchor Tests
- Tests verify **current behavior**, not necessarily "correct" behavior
- They catch regressions and document what the code actually does
- Makes it safer for LLMs to refactor code by establishing behavioral baselines

## Test Data (`test-data/`, committed)
- `*.rsc` — RouterOS script samples at various complexity levels
- `*.rsc.highlight` — saved CHR highlight responses for offline snapshot tests
- `edge-cases/` — targeted: empty, comment-only, single-command, oversize-32k, unicode-heavy
- `eworm/` — scripts from eworm-de/routeros-scripts (GPL, see ATTRIBUTION.md)
- `forum/` — scripts from forum.mikrotik.com
- `*.tikbook` — TikBook notebook format files
- `corpus.sqlite` — checked-in SQLite datastore rebuilt by `scripts/build-corpus-db.ts`; excluded from VSIX because `.vscodeignore` excludes all `test-data/`

## Adding New Tests
- Place tests in `tests/server/` (for server code) or `tests/client/` (for client code), mirroring the source tree
- For new `.rsc` test scripts: add to `test-data/`, run `scripts/capture-snapshots.ts` to generate `.highlight`
- After adding scripts or research sidecars, run `bun run corpus:db` so `test-data/corpus.sqlite` reflects the corpus.
- For mocking `RouterRestClient`: patch the singleton instance property, not the prototype (arrow-function methods are instance-level)
- If you're tempted to write a script to "try something out" — it belongs in `.scratch/`, not next to a `.ts` source file. Promote to `scripts/` when it's worth keeping.
