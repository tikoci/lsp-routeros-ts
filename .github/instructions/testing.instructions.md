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

### Smoke tests (planned — not yet implemented)
- Goal: per deployment context, verify the LSP boots and responds to `initialize` + one semantic-tokens request end-to-end. Catches transport/packaging regressions unit tests cannot.
- Contexts that need smoke coverage: standalone binary (`--stdio`), npm package (via `npx`), web bundle (via a Worker shim). See [`deployment.instructions.md`](deployment.instructions.md#pre-release-checklist).
- Uses a mock RouterOS — smoke tests must not depend on a live CHR. Integration tests cover the CHR side.

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

## Test Data (`test-data/`, gitignored)
- `*.rsc` — RouterOS script samples at various complexity levels
- `*.rsc.highlight` — saved CHR highlight responses for offline snapshot tests
- `edge-cases/` — targeted: empty, comment-only, single-command, oversize-32k, unicode-heavy
- `eworm/` — scripts from eworm-de/routeros-scripts (GPL, see ATTRIBUTION.md)
- `forum/` — scripts from forum.mikrotik.com
- `*.tikbook` — TikBook notebook format files

## Adding New Tests
- Place tests in `tests/server/` (for server code) or `tests/client/` (for client code), mirroring the source tree
- For new `.rsc` test scripts: add to `test-data/`, run `scripts/capture-snapshots.ts` to generate `.highlight`
- For mocking `RouterRestClient`: patch the singleton instance property, not the prototype (arrow-function methods are instance-level)
- If you're tempted to write a script to "try something out" — it belongs in `.scratch/`, not next to a `.ts` source file. Promote to `scripts/` when it's worth keeping.
