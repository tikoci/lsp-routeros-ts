---
description: "Use when changing anything that affects how the LSP ships: package.json, server/package.json, webpack.config.js, build-standalone.sh, workflows, .github/lsp.json, README install sections, or the nvim init script. Covers the five deployment contexts and the pre-release checklist."
applyTo: "package.json,server/package.json,client/package.json,webpack.config.js,build-standalone.sh,.github/workflows/**,.github/lsp.json,README.md,nvim-routeros-lsp-init.lua,docs/**"
---

# Deployment Contexts

The codebase has **three build targets** but ships into **six deployment contexts**. Code that passes unit tests can still break a deployment context (transport, packaging, CORS, shebang, credential flow, editor-specific LSP handler coverage). Track contexts, not just targets.

## The Six Contexts

| # | Context | How users get it | Transport | Credential delivery | Notes |
|---|---------|------------------|-----------|---------------------|-------|
| 1 | **VSCode Desktop** | Marketplace / Open-VSX / VSIX | Node IPC | `workspace/configuration` (standard LSP) | Largest user base. Tested via F5 "Extension Development Host". |
| 2 | **VSCode Web** | `vscode.dev`, `github.dev` | Web Worker | `workspace/configuration` | Requires a CORS proxy in front of RouterOS. TLS cannot be bypassed. Bundled via webpack. |
| 3 | **Standalone native binary** | GitHub Releases (`lsp-routeros-server-*`) | stdio (default) or `--socket=<port>` (experimental) | `workspace/configuration` (if the client implements it) or `ROUTEROSLSP_*` env vars | `bun build --compile`. macOS binaries hit Gatekeeper quarantine — npm is preferred. Generic target: Helix and any other LSP client. |
| 4 | **npm package `@tikoci/routeroslsp`** | `npm install -g @tikoci/routeroslsp` → `routeroslsp --stdio` | stdio | `workspace/configuration`, `initializationOptions`, or `ROUTEROSLSP_*` env vars | Preferred non-VSCode install. Runs `server/dist/server.js` under user's Node ≥18. |
| 5 | **NeoVim** | Standalone binary OR npm package + `nvim-routeros-lsp-init.lua` | stdio | `workspace/configuration` handler implemented in the init script | First-class. Tracks NeoVim API changes (0.10+ required post-refactor; 0.11+ adds `vim.lsp.completion`). Treat the init script as release-blocking when the stdio transport changes. See [`neovim.instructions.md`](neovim.instructions.md). |
| 6 | **GitHub Copilot CLI** | `.github/lsp.json` (repo-scoped) or `~/.copilot/lsp-config.json` (user-scoped) | stdio | **`initializationOptions` primary**, with `ROUTEROSLSP_*` env fallback — Copilot CLI does **not** implement `workspace/configuration` | Depends on context 4 (npx). If npm publish is broken, Copilot CLI is broken. |

## Context-Specific Gotchas

### VSCode Desktop
- `http.proxySupport: "fallback"` in user settings is required for self-signed TLS to work end-to-end.
- `.vscodeignore` controls exactly what lands in the VSIX — audit it when adding root-level files (see [`build.instructions.md`](build.instructions.md)).

### VSCode Web
- No Node APIs. `fs`, `https`, `http`, `stream` are nullified by the webpack config — don't introduce code paths that need them.
- `checkCertificates` setting is ignored; the browser enforces TLS. A CORS proxy with a valid cert is required.
- Semantic tokens capability must exist on both `extension.web.ts` and `extension.ts` — regressions often happen on one side only.

### Standalone native binary
- Built for 8 platform/arch combos in `build.yaml`. Windows arm64 is new; Windows x64 works but is rarely exercised.
- `--stdio` is the only fully-supported transport. `--socket=<port>` is experimental — don't rely on it for testing without explicit verification.
- macOS binaries require `xattr -d com.apple.quarantine` to run. The install docs should steer users to the npm package instead.

### NeoVim
- `nvim-routeros-lsp-init.lua` implements the `workspace/configuration` handler on the client side — removing or reorganizing it breaks settings delivery. The standalone server now also reads `ROUTEROSLSP_*` env vars, but the init script remains the primary NeoVim path.
- Semantic highlight colors are mapped via `@lsp.type.<tokenType>` namespace; keep aligned with `semanticTokenTypes` in the root `package.json`.
- After changes to the stdio transport or server startup, run `bun run bun:exe` and open a `.rsc` file in NeoVim — `:LspInfo` and `:messages` should be clean.
- 📋 lspconfig registry contribution is tracked in BACKLOG; until then, NeoVim users copy the init script manually.

### npm package (`@tikoci/routeroslsp`)
- Bin entry: `"routeroslsp": "./dist/server.js"`. The file **must** start with `#!/usr/bin/env node` — `bun build` does not emit a shebang, so `npm:publish` prepends one before publishing. If the shebang step is skipped, the bin is not executable via `npm install -g`.
- CI publishes conditionally on `NPM_TOKEN` being set (`if: env.NPM_TOKEN != ''`). When verifying "is the latest version live on npm", check `https://registry.npmjs.org/@tikoci/routeroslsp/latest` against `server/package.json` — remember `package.json` is always the **next** version (CI bumps after publish).
- No maintainer should `npm publish` locally. CI is the only supported path.

### GitHub Copilot CLI
- Copilot CLI is an **LSP client**, not an MCP server. It reads `.github/lsp.json` (repo) or `~/.copilot/lsp-config.json` (user). Managing the LSP interactively uses the `/lsp` slash command inside Copilot CLI.
- Because Copilot CLI does not support `workspace/configuration`, settings are normally delivered via `initializationOptions.routeroslsp.{baseUrl,username,password}`. `shared.ts` also accepts `ROUTEROSLSP_*` env vars for standalone-style launches — do not remove `initializationOptions` support.
- The current `.github/lsp.json` uses `npx --yes @tikoci/routeroslsp --stdio`. This works only if (a) the npm package is published with a valid shebang, and (b) Node.js is on the user's PATH. Both need to be confirmed on each pre-release.
- Never commit real credentials in `.github/lsp.json`. Placeholders should be obviously fake (`REPLACE_ME_USERNAME`/`REPLACE_ME_PASSWORD`), and README should point users at `~/.copilot/lsp-config.json` for their real creds.
- Internal write operations should use the server execute-command interface (`router.validateScript` / `router.executeScript`) with explicit per-call credentials; they must not rely on ambient Copilot CLI settings.

## Pre-release Checklist

Before promoting a build from "pre-release" to "stable" — or before a pre-release can be trusted as representative — each context needs a signal. Automate what you can; the goal is that CI green ≈ pre-release works.

**Baseline (automated on every push/PR via `ci.yaml`)**: install → compile → unit tests → lint (typecheck + biome) → stdio smoke (Node-bundled + standalone binary against a mocked RouterOS). If `ci.yaml` is red on `main`, no release should be triggered.

- [x] **Pre-release gate** — `ci.yaml` green on the commit being released. Confirms compile, types, unit tests, and stdio smoke all pass.
- [ ] **Context 1 (VSCode Desktop)** — VSIX installs, `F5` smoke passes, semantic tokens + completion + diagnostics each verified against a live CHR at least once per release cycle. Ideally: `@vscode/test-electron` job in CI (📋 tracked in BACKLOG).
- [ ] **Context 2 (VSCode Web)** — webpack build produces web bundles without errors (covered by `bun run compile` in CI); web entry point loads in `@vscode/test-web`. Manual check: `vscode.dev` load + semantic tokens against a CORS-proxied CHR. 📋 Worker-shim smoke test still needed.
- [x] **Context 3 (Standalone binary)** — `compile:exe` builds the native binary in CI, and `test:smoke --standalone` exercises `--stdio` against the mock router. Cross-platform builds for the other 7 targets still happen only in `build.yaml`; manual verification of darwin-arm64 + windows-x64 per release cycle.
- [ ] **Context 4 (npm package)** — after publish, `npx --yes @tikoci/routeroslsp --stdio` on a clean machine (or container) launches the server and responds to `initialize`. Shebang present in `server/dist/server.js`. Version on npmjs.org matches what was just built. (CI's smoke covers the bundled `server.js` directly but not the npm-installed bin path.)
- [ ] **Context 5 (NeoVim)** — standalone binary (or npm install) + `nvim-routeros-lsp-init.lua` loads cleanly in NeoVim 0.10+; a `.rsc` file gets semantic tokens from a connected CHR. This is the canonical non-VSCode end-to-end check — if NeoVim works, contexts 3 and 4 almost certainly do too.
- [ ] **Context 6 (Copilot CLI)** — with the updated npm version live, a Copilot CLI session can load `.github/lsp.json`, run `/lsp`, and get a healthy status for `routeroslsp`. At minimum: manual verification until automated.
- [ ] **CHR integration** — `integration.test.ts` passes against a CHR booted via [`tikoci/quickchr`](https://github.com/tikoci/quickchr). quickchr is explicitly designed for this (version-pinned, predictable `/console/inspect`, headless-in-CI). Prefer it over the maintainer's local CHR for any gate.

## When to Update This File

- A new deployment context is added (e.g. Zed, Neovim official registry) — add a row and checklist item.
- A context's gotcha is newly discovered or resolved — update the corresponding bullet.
- Pre-release checklist items graduate from manual to automated — cross them off and link to the CI step.
- Credential flow changes — update Context 5 notes since that's the most fragile path.

Don't turn this into a changelog. If an item's story is interesting, write it up in [`DESIGN.md`](../../DESIGN.md) and link.
