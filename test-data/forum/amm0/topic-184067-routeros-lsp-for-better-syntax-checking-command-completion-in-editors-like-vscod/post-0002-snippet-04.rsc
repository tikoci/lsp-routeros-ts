# Source: https://forum.mikrotik.com/t/routeros-lsp-for-better-syntax-checking-command-completion-in-editors-like-vscode-neovim/184067/2
# Topic: 🧬 RouterOS LSP for better syntax checking & command completion in editors like VSCode & NeoVim
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/console/inspect request=syntax path=ip,address,add                                        
Columns: TYPE, SYMBOL, SYMBOL-TYPE, NESTED, NONORM, TEXT
TYPE    SYMBOL     SYMBOL-TYPE  NESTED  NONORM  TEXT                                   
syntax             collection        0  yes                                            
syntax  address    explanation       1  no      Local IP address                       
syntax  broadcast  explanation       1  no      Broadcast address                      
syntax  comment    explanation       1  no      Short description of the item          
syntax  copy-from  explanation       1  no      Item number                            
syntax  disabled   explanation       1  no      Defines whether item is ignored or used
syntax  interface  explanation       1  no      Interface name                         
syntax  netmask    explanation       1  no      Network mask                           
syntax  network    explanation       1  no      Network prefix
