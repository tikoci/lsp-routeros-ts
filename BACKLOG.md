# RouterOS LSP — Backlog

> Active and planned work only. Durable findings belong in `docs/`, workflow rules
> belong in `.github/instructions/`, architecture rationale belongs in
> `DESIGN.md`/`CLAUDE.md`, and shipped user-visible changes belong in
> `CHANGELOG.md`.

## How to use this file

- Keep items actionable: each bullet should be something an agent or maintainer can
  pick up and finish.
- Remove completed items after the relevant documentation, tests, or changelog entry
  exists. Do not keep implementation history here.
- If research produces durable facts, move the write-up to `docs/` and leave only
  the remaining follow-up task here.
- If an item changes build, packaging, deployment, tests, or editor integration,
  check the scoped instruction files before implementing.

Status markers: 📋 planned, 🔄 in progress, 💡 exploratory. Priority markers:
**P0** release-blocking or unlocks near-term work, **P1** important, **P2** later.

## Reference map for completed research

These docs are the source of truth for completed research. Use them as design input;
do not duplicate their findings back into this backlog.

| Topic | Source of truth | Notes |
| --- | --- | --- |
| Highlight wire format and live lexical behavior | [`docs/highlight-format.md`](docs/highlight-format.md) | Captured against RouterOS 7.9.2, 7.23.2, and 7.24rc2. |
| parseIL format and `:parse` behavior | [`docs/parseil-format.md`](docs/parseil-format.md) | Captured against RouterOS 7.20.8, 7.22.1, and 7.23rc1. |
| Syntax-inspection probe selection | [`docs/syntax-inspection-map.md`](docs/syntax-inspection-map.md) | Cross-probe decision and provenance layer for future skills/consumers. |
| `completion`/`syntax`/`child` response shapes | [`docs/inspect-shapes.md`](docs/inspect-shapes.md) | Curated-context captures on RouterOS 7.9.2, 7.23.2, and 7.24rc2. |
| Required-argument probe | [`docs/required-args.md`](docs/required-args.md) | Version-tagged execute-time signal and unresolved edge cases. |
| rosetta/LSP docs enrichment | [`docs/rosetta-alignment.md`](docs/rosetta-alignment.md) | No runtime rosetta dependency; static JSON first. |
| canonicalize audit | [`docs/canonicalize-audit.md`](docs/canonicalize-audit.md) | Upstream rosetta parser alignment and remaining hardening. |
| Corpus DB, snapshots, smoke, CHR tests | [`.github/instructions/testing.instructions.md`](.github/instructions/testing.instructions.md) | Test data and research harness workflow. |
| Build/release/package mechanics | [`.github/instructions/build.instructions.md`](.github/instructions/build.instructions.md) and [`.github/instructions/deployment.instructions.md`](.github/instructions/deployment.instructions.md) | Six deployment contexts and release gate. |
| RouterOS REST and `/console/inspect` basics | [`.github/instructions/routeros-api.instructions.md`](.github/instructions/routeros-api.instructions.md) | Endpoint formats, encoding, request types. |

## Working order: research before features

Features touching `controller.ts`, `model.ts`, `tokens.ts`, or RouterOS command
semantics should be grounded in measured RouterOS behavior first. The usual path is:

1. Add a reusable harness under `scripts/` or a throwaway probe in `.scratch/`.
2. Store normalized results in `test-data/corpus.sqlite` when the data is durable.
3. Write conclusions in `docs/` or `DESIGN.md`.
4. Implement the LSP feature after the response shape and edge cases are known.

## P0 — Release and deployment gate

- 📋 **Per-context smoke automation** — stdio smoke covers the bundled Node server
  and standalone binary with a mocked RouterOS. Add coverage for VSCode Desktop,
  VSCode Web/Worker, npm-installed bin, NeoVim, and Copilot CLI.
- 📋 **CI-booted CHR integration** — run `integration.test.ts` against a
  [`tikoci/quickchr`](https://github.com/tikoci/quickchr)-booted CHR in GitHub
  Actions.
- 📋 **npm publish audit** — confirm each release publishes
  `@tikoci/routeroslsp`, preserves the shebang, and keeps the npm version aligned
  with the release artifact.
- 📋 **Copilot CLI launch verification** — after npm publish, verify
  `.github/lsp.json` / `npx --yes @tikoci/routeroslsp --stdio` loads in Copilot
  CLI and reports healthy via `/lsp`.
- 📋 **VSCode integration tests** — boot real VSCode with `@vscode/test-electron`,
  install the VSIX, and verify semantic tokens, diagnostics, and completion.
- 📋 **Web target smoke** — add a Worker-shim or `@vscode/test-web` signal for the
  web bundles.

## P0 — Research blockers

- 📋 **`[research: inspect-shapes]` Catalog `/console/inspect` responses** —
  schemas are documented: `highlight` in [`docs/highlight-format.md`](docs/highlight-format.md),
  `completion`/`syntax`/`child` in [`docs/inspect-shapes.md`](docs/inspect-shapes.md)
  (curated-context captures on 7.9.2/7.23.2/7.24rc2 via
  `scripts/collect-inspect-shapes.ts`). Remaining: the representative
  corpus-position sweep into `inspect_responses` in `test-data/corpus.sqlite`.
- 📋 **`[research: completion-tricks]` Validate fake-space / fake-equals
  heuristics** — measure when synthetic trailing space or `=` probes improve,
  change, or break completions; define safe application rules.
- 📋 **`[research: 28kb]` Investigate the highlight timing cliff** — sweep document
  sizes and syntax compositions around the ~28 KiB inflection point, compare
  request types, and produce a mitigation recommendation.
- 📋 **`[research: md-embedded]` RouterOS fenced blocks in Markdown** — prove
  range remapping for `routeros` fenced code blocks before deciding whether support
  belongs in the server or client pre-processing.

## P1 — rosetta and docs enrichment

- 📋 **`routeros-docs-links.json` artifact** — generate or vendor a small
  path-to-docs URL map from rosetta for web-safe hover/document-link enrichment.
- 📋 **Hover doc links** — append documentation links for `path` and `cmd-name`
  tokens using the static docs-link artifact.
- 📋 **`textDocument/documentLink`** — return document links for RouterOS path
  token ranges.
- 📋 **Completion documentation** — populate completion `detail` and
  `documentation` from live completion text first, then rosetta/property data when
  the data source is available.
- 📋 **Lite DB + sql.js spike** — after rosetta publishes a lite DB artifact,
  measure sql.js loading and web bundle impact in `.scratch/`.
- 📋 **Vendor or depend on `canonicalize.ts`** — pull upstream rosetta parser
  improvements after the remaining hardening items land, preserving the
  pluggable `isVerb` shape.
- 📋 **Upstream rosetta asks** — track docs-link export, lite DB artifact,
  `command_path` on properties, path lookup tooling, and released schema-node data
  in rosetta issues rather than duplicating the detail here.

## P1 — LSP feature improvements

### Completion

- 📋 Use `request=syntax` for richer completion metadata after
  `[research: inspect-shapes]`.
- 📋 Apply fake-space and fake-equals completion probes after
  `[research: completion-tricks]`.
- 📋 Populate `CompletionItem.detail` and `documentation`.
- 📋 Make trigger characters configurable instead of hardcoding `:=/ $[`.

### Hover

- 📋 Show command and argument descriptions.
- 📋 Show type information and value ranges.
- 📋 Replace debug-style token hover with user-facing help.
- 📋 Add a "Show parseIL" command or hover supplement using the documented capture
  path in `docs/parseil-format.md`.

### Diagnostics

- 📋 Detect RouterOS data type mismatches after syntax response shapes are
  characterized.
- 📋 Improve multi-error reporting from `highlight` error tokens.
- 📋 Add severity levels for warnings, obsolete syntax, and informational hints.
- 📋 Map `syntax-obsolete` to warnings.

### New LSP capabilities

- 📋 Signature Help for command arguments.
- 📋 Code Actions for deprecated commands and simple syntax fixes.
- 📋 Formatting for basic RouterOS script structure.
- 📋 Folding Ranges from parseIL block boundaries.
- 📋 Definition/References via parseIL scope reconstruction.
- 📋 Inlay Hints for inline type/value help.
- 📋 Code Lens for RouterOS path context.
- 📋 Document Symbols for functions, not just variables.

## P1 — VSCode extension and UX

- 📋 **Run on Router command** — if added, wrap `router.validateScript` /
  `router.executeScript` and preserve explicit per-call credentials.
- 📋 **Show RouterOS Version command** — display connected device version details.
- 📋 **Export Config command** — fetch and display selected running-config sections.
- 📋 **Better watchdog notifications** — include clearer context and recovery
  actions.
- 📋 **Status bar indicator** — show connection state and RouterOS version.
- 📋 **Snippet support** — provide common RouterOS script patterns.
- 📋 **Walkthrough screenshots** — add visual examples to the setup walkthrough
  when the screenshot workflow is available.

## P1 — Documentation

- 📋 **User manual** — create a guide beyond README covering setup,
  troubleshooting, features, and customization.
- 📋 **Developer guide** — document how to add LSP features and where handlers,
  tests, and docs belong.
- ✅ **RouterOS inspect API reference** — landed as
  [`docs/highlight-format.md`](docs/highlight-format.md) (`highlight`) and
  [`docs/inspect-shapes.md`](docs/inspect-shapes.md) (`completion`, `syntax`,
  `child`).

## P1 — Architecture and internals

### Performance

- 📋 Incremental document sync instead of full-document sync.
- 📋 Debounce/throttle RouterOS API calls during rapid typing.
- 📋 Request cancellation when a document changes while a request is in flight.
- 📋 Production mitigation for the 28 KiB highlight cliff after `[research: 28kb]`.

### Code organization

- 📋 Extract completion logic from `controller.ts`.
- 📋 Separate execute-command handlers into focused modules/functions.
- 📋 Add TypeScript interfaces for RouterOS API response shapes.

### Web target

- 📋 Test the web extension regularly, not just the webpack build.
- 📋 Consider a bundled or documented CORS proxy only after the user-facing guide
  is clear.

## P1 — Cross-extension integration

- 📋 **TikBook / Markdown fenced blocks** — semantic highlighting, diagnostics, and
  completion inside `routeros` fenced code blocks in `.rsc.md`, `.tikbook.rsc.md`,
  and possibly any Markdown file after `[research: md-embedded]`.
- 📋 **TikBook cell execution via LSP** — evaluate whether notebook execution
  should move from TikBook into LSP commands.
- 📋 **TikBook notebook diagnostics** — use LSP diagnostics for notebook cells.
- 📋 **restraml schema validation** — explore deeper validation against RAML/OpenAPI
  schemas.
- 📋 **QEMU CHR management** — integrate with TikBook/quickchr-style version
  switching when the responsibility boundary is clear.
- 📋 **Cross-project AI tool exposure alignment** — decide how TikBook, RouterOS
  LSP, and rosetta divide responsibility for `languageModelTools`, MCP, and chat
  participants. Keep RouterOS LSP focused on pure LSP behavior until settled.

## P2 — NeoVim and standalone

- 📋 **nvim-lspconfig entry** — contribute RouterOS LSP config to the official
  NeoVim LSP registry.
- 📋 **Socket transport testing** — validate `--socket=<port>` before documenting
  it as supported.

## P2 — Exploratory ideas

- 💡 Offline mode with cached syntax for limited editing.
- 💡 Multi-router support for switching between RouterOS versions/devices.
- 💡 RouterOS terminal integration in VSCode.
- 💡 Copilot Chat participant for `@routeros` mentions.
- 💡 WebMCP tool wrapper for LSP capabilities.
