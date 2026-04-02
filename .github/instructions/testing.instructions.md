---
applyTo: "tests/**,test-data/**"
description: "Use when writing or modifying tests. Covers test strategy, anchor testing pattern, QEMU CHR integration testing, and test data conventions."
---

# Testing Guidelines

## Current State
No automated test runner is configured yet. The `test-data/` directory has sample files for manual testing. Setting up `bun test` is a planned task (see BACKLOG.md).

## Test Strategy: Anchor Tests
Follow the "anchor test" philosophy from `~/CLAUDE.md`:
- Tests verify **current behavior**, not necessarily "correct" behavior
- They catch regressions and document what the code actually does
- Makes it safer for LLMs to refactor code by establishing behavioral baselines
- Use `bun test` as the runner

## What to Test First
Priority order for adding tests:
1. **tokens.ts** — parse known highlight responses, verify tokenRanges output
2. **routeros.ts** — mock Axios responses, verify request formation and response parsing
3. **model.ts** — test LspDocument caching, invalidation, lazy evaluation
4. **controller.ts** — test LSP handlers with mock documents and transport

## Mocking RouterOS
- Unit tests should mock `RouterRestClient` HTTP calls (don't hit a real router)
- Save real RouterOS responses as JSON fixtures in `test-data/`
- For integration tests, use QEMU CHR (pattern from `~/GitHub/restraml/CLAUDE.md`)

## QEMU CHR Integration Tests
For E2E tests against a real RouterOS instance:
1. Download CHR .raw image from `download.mikrotik.com`
3. Boot with `qemu-system-x86_64` and user-mode networking (host:9180→VM:80)
4. Wait for REST API availability (poll loop)
5. Run tests against `http://localhost:9180`
6. Cleanup QEMU process

## Test Data Files
- `*.rsc` — RouterOS script samples (various complexity levels)
- `*.tikbook` — TikBook notebook format files
- `from-scratch.tikbook` — Empty/minimal notebook
- `sample.rsc` — General-purpose test script
- `piano.rsc` — Edge case testing

## File Naming
- Test files: `{module}.test.ts` (e.g., `tokens.test.ts`)
- Test fixtures: `test-data/{description}.json` for mocked API responses
- Integration data: `tests/*.rsc` for full-script testing
