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

## VSIX Pre-release Convention
VSCode uses odd minor versions for pre-releases (e.g. `0.7.x` is pre-release, `0.8.x` is stable). Scripts:
- `vsix:package` — stable release (`vsce package`)
- `vsix:package:prerelease` — pre-release (`vsce package --pre-release`)

CI's `build.yaml` has a `prerelease` boolean input that selects between them.

## Version Bumping
- `bump:patch` — syncs patch version across root, server, and client `package.json` files
- `bump:minor` — syncs minor version across all three `package.json` files
