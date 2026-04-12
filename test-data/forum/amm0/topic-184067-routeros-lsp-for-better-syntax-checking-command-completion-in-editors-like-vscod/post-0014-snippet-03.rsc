# Source: https://forum.mikrotik.com/t/routeros-lsp-for-better-syntax-checking-command-completion-in-editors-like-vscode-neovim/184067/14
# Topic: 🧬 RouterOS LSP for better syntax checking & command completion in editors like VSCode & NeoVim
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
    :local outside "outside"
    :local fn do={
        :put "local function can see '$outside' (outside)"
    }
    :global FN do={ 
        :put "but global cannot see '$outside' (outside)"
    }
    $fn
    $FN
}
