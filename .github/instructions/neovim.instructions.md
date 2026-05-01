---
applyTo: "**/*.lua"
description: "Use when editing NeoVim Lua configuration for RouterOS LSP. Covers LSP client setup, semantic highlighting, and standalone server integration."
---

# NeoVim LSP Integration

## Overview
`nvim-routeros-lsp-init.lua` configures NeoVim to use the npm-installed or standalone LSP server. It handles:
- LSP client creation with `vim.lsp.start()`
- `workspace/configuration` handler (delivers settings to the LSP)
- Semantic token highlight colors (maps LSP token types to NeoVim highlights)
- `.rsc` filetype detection

## Server command

The preferred non-VSCode install is the npm package:

```bash
npm install -g @tikoci/routeroslsp
```

The LSP server then runs as `routeroslsp --stdio`.

The native standalone binary remains supported for users without Node.js. Release
artifacts are built for linux-x64, linux-arm64, linux-x64-musl,
linux-arm64-musl, darwin-x64, darwin-arm64, windows-x64, and windows-arm64.
Default manual install location is `~/.bin/`.

## Configuration Handler
NeoVim must implement the `workspace/configuration` handler to deliver `routeroslsp.*` settings to the server. The current `config_handler` function does this — don't remove it.

## Color Mapping
Semantic token colors should match RouterOS CLI colors. The highlight setup uses `vim.api.nvim_set_hl()` with the `@lsp.type.<tokenType>` namespace. Token types match the `semanticTokenTypes` declared in `package.json`.

## Filetype Detection
The script sets up autocmds for `.rsc` files to launch the LSP. Keep filetype patterns aligned with `package.json` `languages[0].extensions` and `filenamePatterns`.

## Testing
After changes:
1. Build standalone: `bun run bun:exe`
2. Binary copies to `~/.bin/lsp-routeros-server`
3. Open `.rsc` file in NeoVim
4. Check `:LspInfo` and `:messages` for errors
5. Test completion with `<C-x><C-o>` in insert mode

## Future Work
- Contribute to nvim-lspconfig registry
- Improve from single-file script to proper NeoVim plugin structure
