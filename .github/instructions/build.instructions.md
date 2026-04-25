---
description: "Use when modifying build scripts, package.json scripts, webpack config, CI workflows, or build-standalone.sh. Covers the three build targets and their toolchains."
applyTo: "package.json,webpack.config.js,build-standalone.sh,.github/workflows/**,tsconfig.json,**/tsconfig.json"
---

# Build System

## Three Build Targets

| Target | Tool | Entry | Output |
|--------|------|-------|--------|
| Client (desktop) | `bun build` | `client/src/extension.ts` | `client/dist/extension.js` (CJS) |
| Server (desktop) | `bun build` | `server/src/server.ts` | `server/dist/server.js` (CJS) |
| Standalone binary | `bun build --compile` | `server/src/server.ts` | `lsp-routeros-server` (native) |
| Client (web) | `webpack` | `client/src/extension.web.ts` | `client/dist/extension.web.js` |
| Server (web) | `webpack` | `server/src/server.web.ts` | `server/dist/server.web.js` |

## Why Both Bun and Webpack
- Bun: Handles Node.js CJS compilation and native binary compilation
- Webpack: Required for Web Worker bundling with browser polyfills (`path-browserify`, `util`)
- Don't try to unify — the split is intentional

## Script Chain
`compile` = `compile:client` → `compile:server` → `compile:exe` → `compile:web`

## Monorepo Structure
Three `package.json` files with separate dependency trees:
- Root `package.json` — scripts, devDependencies, VSCode extension manifest
- `client/package.json` — `vscode-languageclient`
- `server/package.json` — `vscode-languageserver`, `axios`

`bun install` at root triggers `postinstall` which runs `bun install` in client/ and server/.

## Cross-Platform Standalone Builds
`build-standalone.sh` and CI build for: linux-x64, linux-arm64, darwin-x64, darwin-arm64, linux-x64-musl, linux-arm64-musl, windows-x64, windows-arm64.

Windows arm64 has not been tested and may not compile.

## VSIX Packaging
`npx @vscode/vsce package --no-dependencies` — packages the extension without bundling node_modules (dependencies are bundled by bun build).

## npm Package Publishing
`npm:publish` script: `compile:server` → prepend `#!/usr/bin/env node` shebang → `cd server && npm publish`.

The shebang step is required because `bun build` outputs plain JS without a shebang. npm/yarn/pnpm may create symlinks to the bin entry instead of wrapper scripts, which requires the shebang to be present for the file to be executable.

CI uses `NODE_AUTH_TOKEN` (from `NPM_TOKEN` secret) with `registry-url: "https://registry.npmjs.org"` on the `setup-node` step — the `registry-url` is mandatory for `setup-node` to write the token into `.npmrc`.

**`.vscodeignore` is critical** — it controls exactly what files end up in the VSIX. Review it whenever you add new root-level files, new `dist/` outputs, new docs, or new tooling config. Use `npx @vscode/vsce ls --no-dependencies` to see the current inclusion list before packaging or pushing. Developer/AI context files (e.g. `CLAUDE.md`, `DESIGN.md`, `BACKLOG.md`, `biome.json`, `bunfig.toml`, `.markdownlint*`, `.claude/`) and NeoVim-only files must **never** appear in the VSIX.

## VSIX Pre-release Convention
VSCode uses odd minor versions for pre-releases (e.g. `0.7.x` is pre-release, `0.6.x` is stable). Scripts:
- `vsix:package` — stable release (`vsce package`)
- `vsix:package:prerelease` — pre-release (`vsce package --pre-release`)

CI's `build.yaml` has a `prerelease` boolean input that selects between them.

## Version Bumping
- `bump:patch` — syncs patch version across root, server, and client `package.json` files
- `bump:minor` — syncs minor version across all three `package.json` files
- Version bumps are not user-visible changes — don't add them to CHANGELOG.md

## CI vs Release Workflows

Two GitHub Actions workflows split validation from publishing:

- **`.github/workflows/ci.yaml`** — runs on `push` to `main` and `pull_request`. Steps: install → `bun run compile` → `bun run test` → `bun run lint` → `bun run test:smoke`. Stops there. No packaging, no `gh release`, no npm publish. This is the regression gate.
- **`.github/workflows/build.yaml`** — `workflow_dispatch` only. Replays the same gate (test, lint, smoke), then packages VSIX, cross-compiles 8 standalone binaries, creates the GitHub Release, publishes to VSCode Marketplace + Open-VSX + npm, and bumps versions for the next cycle.

**Keep the gate steps in sync.** If you add a step to `ci.yaml` (e.g., a new test tier), add the same step to `build.yaml` so a green release implies a green CI. Don't let `build.yaml` drift looser than `ci.yaml` — that re-creates the original problem (typecheck regressions only surfacing at release time).

`ci.yaml` uses `concurrency: cancel-in-progress` so a new push to a branch supersedes any in-flight run on the same ref. `build.yaml` does **not** cancel in-progress runs (a half-cancelled release is worse than waiting).

## CHANGELOG.md

`CHANGELOG.md` is shown as "Release Notes" in the VSCode extension UI — write for users, not developers. See `changelog.instructions.md` for full conventions. Key points:
- Update when making user-visible changes (features, bug fixes, breaking changes)
- Each release has **Changes** (features/improvements) and **Fixes** (bugs, summarized cleanup)
- Don't log version bumps, CI-only changes, or lint fixes individually
