---
applyTo: "**/*.test.ts,test-data/**,bunfig.toml,**/test-preload.ts,**/capture-snapshots.ts"
description: "Use when writing or modifying tests. Covers test tiers, anchor testing pattern, snapshot workflow, and CHR integration."
---

# Testing Guidelines

## Test Runner & Config

- `bun test server/src/ client/src/` runs all tests (~326 tests, <500ms without CHR)
- `bunfig.toml` preloads `server/src/test-preload.ts` to silence `log.*` output
- Test files are co-located with source: `server/src/*.test.ts`, `client/src/*.test.ts`
- `server/tsconfig.json` excludes `*.test.ts`, `test-preload.ts`, and `capture-snapshots.ts` from compilation

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
- Generate snapshots: `bun run server/src/capture-snapshots.ts` (requires live CHR)

### Client tests (no VSCode dependency)
- `watchdog-errors.test.ts` — tests `toErrorInfo` and `getTextFromError` from `watchdog-errors.ts`
- These are pure functions extracted from `watchdog.ts` to avoid VSCode import issues

### Integration tests (requires live CHR)
- `integration.test.ts` — connects to CHR, sends all `test-data/**/*.rsc` through `inspectHighlight`
- Auto-skips when CHR is unreachable
- Override CHR address: `ROUTEROS_TEST_URL=http://... bun test server/src/integration.test.ts`

## Assessment & Profiling Tools (not tests — standalone scripts)

### Dataset assessment (`assess-dataset.ts`)
- Runs all `test-data/**/*.rsc` files through CHR highlight API
- Reports: timing, token quality, unknown types, error tokens, CLI prompts, data signals
- Usage: `bun run server/src/assess-dataset.ts [--json] [--concurrency=N]`
- JSON output: `test-data/assessment-results.json` (gitignored)

### Performance profiling (`profile-timing.ts`)
- Tests size→time relationship by truncating scripts at progressive sizes (128B → 32KB)
- Includes synthetic controls (pure comments, simple commands, complex scripting, mixed paths)
- Also profiles real files (eworm/global-functions.rsc, oversize-32k.rsc, complex/piano.rsc)
- Usage: `bun run server/src/profile-timing.ts`
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
- Co-locate with the source file being tested
- For new `.rsc` test scripts: add to `test-data/`, run `capture-snapshots.ts` to generate `.highlight`
- For mocking `RouterRestClient`: patch the singleton instance property, not the prototype (arrow-function methods are instance-level)
