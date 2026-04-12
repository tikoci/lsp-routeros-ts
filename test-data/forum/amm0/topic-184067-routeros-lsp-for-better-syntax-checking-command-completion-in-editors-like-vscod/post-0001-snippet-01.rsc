# Source: https://forum.mikrotik.com/t/routeros-lsp-for-better-syntax-checking-command-completion-in-editors-like-vscode-neovim/184067/1
# Topic: 🧬 RouterOS LSP for better syntax checking & command completion in editors like VSCode & NeoVim
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# RouterOS LSP

![LSP running VSCode GIF](https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExNDl4NXg5ZXB0YWd2Z2s5b2t0Z2t6enN6Y3NmbTRsZ2o5dWM3MTJqMSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/Rm4TUg15fUuUhHVvSx/giphy.gif)

RouterOS LSP is a language server that provides syntax highlighting, code completion, diagnostics, and other intelligent language features for RouterOS scripts (.rsc files) in most LSP-capable editors. By querying a live RouterOS device via the REST API, the LSP ensures syntax always matches your RouterOS version.

## Supported Features

RouterOS LSP supports:

- **Completion** — code suggestions and tab completion
- **Diagnostics** — real-time syntax error reporting
- **Semantic Tokens** — syntax highlighting that matches RouterOS CLI colors
- **Hover Information** — help and variable inspection (Work in Progress)
- **Document Symbols** — navigate variables and commands (Work in Progress)
- **References** — find usages
- **Definition Lookup** — jump to definitions
- **VSCode Commands** — additional actions via Command Palette (VSCode only)
- **Walkthrough** — guided setup wizard (VSCode only)
