# Source: https://forum.mikrotik.com/t/routeros-lsp-for-better-syntax-checking-command-completion-in-editors-like-vscode-neovim/184067/2
# Topic: 🧬 RouterOS LSP for better syntax checking & command completion in editors like VSCode & NeoVim
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/console/inspect request=syntax input="/ip/address/add interface=ether1 address=1.1.1.1/24"
Columns: TYPE, SYMBOL, SYMBOL-TYPE, NESTED, NONORM, TEXT
TYPE    SYMBOL     SYMBOL-TYPE  NESTED  NONORM  TEXT                     
syntax  Netmask    definition        0  no      IpNetmask | Num          
syntax  IpNetmask  definition        1  no      A.B.C.D                  
syntax  Num        definition        1  no      0..32    (integer number)
