---
applyTo: "**/*.lua"
description: "Use when editing NeoVim Lua configuration for RouterOS LSP. Covers LSP client setup, semantic highlighting, and standalone server integration."
---

# NeoVim LSP Integration

## Overview
`nvim-routeros-lsp-init.lua` configures NeoVim to use the standalone LSP server binary. It handles:
- LSP client creation with `vim.lsp.start()`
- `workspace/configuration` handler (delivers settings to the LSP)
- Semantic token highlight colors (maps LSP token types to NeoVim highlights)
- `.rsc` filetype detection

## Standalone Binary
The LSP server runs as `lsp-routeros-server --stdio`. It's compiled via `bun build --compile` for multiple platforms:
- `lsp-routeros-server-darwin-arm64`, `darwin-x64`
- `lsp-routeros-server-linux-arm64`, `linux-x64`
- `lsp-routeros-server-windows-x64.exe`
Default install location: `~/.bin/`

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
- Update for modern NeoVim (0.10+) APIs
- Support lazy.nvim plugin manager setup
- Contribute to nvim-lspconfig registry
- Improve from single-file script to proper NeoVim plugin structure
