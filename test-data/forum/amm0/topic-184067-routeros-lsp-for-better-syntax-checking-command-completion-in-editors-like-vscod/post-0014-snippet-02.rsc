# Source: https://forum.mikrotik.com/t/routeros-lsp-for-better-syntax-checking-command-completion-in-editors-like-vscode-neovim/184067/14
# Topic: 🧬 RouterOS LSP for better syntax checking & command completion in editors like VSCode & NeoVim
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
  :local outside "outside"
  /ip address { 
    :local inside "inside"
    :put "ip seeing '$outside' (outside)"
    /interface {
        :local reallyinside "reallyinside"
        :put "my parent is '$inside', but I can see '$outside'"
        ethernet {
            :put "ethernet is '$reallyinside' (reallyinstead)"
        }
    }
  }
  :put "looking from outside i cannot see '$inside' (inside)"
}
