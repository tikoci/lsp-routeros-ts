# Source: https://forum.mikrotik.com/t/routeros-lsp-for-better-syntax-checking-command-completion-in-editors-like-vscode-neovim/184067/2
# Topic: 🧬 RouterOS LSP for better syntax checking & command completion in editors like VSCode & NeoVim
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/console/inspect request=completion input="/ip/address/add interface=ether1 address=1.1.1.1/24"
Columns: TYPE, COMPLETION, STYLE, OFFSET, PREFERENCE, SHOW, TEXT
TYPE        COMPLETION  STYLE        OFFSET  PREFERENCE  SHOW  TEXT                                                                                 
completion  <value>     none             49  -1          no    literal value that consists only of digits, letters and characters -.,:<>/|+_*&^%#@!~
completion              none             51  80          no    whitespace                                                                           
completion  ;           syntax-meta      51  40          no    end of command                                                                       
/console/inspect request=completion input="/ip/address/add interface=ether1 address=1.1.1.1/24c"
Columns: TYPE, COMPLETION, STYLE, OFFSET, PREFERENCE, SHOW, TEXT
TYPE        COMPLETION  STYLE        OFFSET  PREFERENCE  SHOW  TEXT                                                                                 
completion  <value>     none             49  -1          no    literal value that consists only of digits, letters and characters -.,:<>/|+_*&^%#@!~
completion              none             52  80          no    whitespace                                                                           
completion  ;           syntax-meta      52  40          no    end of command          

# and adding a <space> at end of input= does show the attributes that are possible                                                             
/console/inspect request=completion input="/ip/address/add interface=ether1 address=1.1.1.1/24 " 
Columns: TYPE, COMPLETION, STYLE, OFFSET, PREFERENCE, SHOW, TEXT
TYPE        COMPLETION  STYLE        OFFSET  PREFERENCE  SHOW  TEXT                                   
completion  !           none             52          80  no    whitespace                             
completion  broadcast   arg              52          95  yes   Broadcast address                      
completion  comment     arg              52          96  yes   Short description of the item          
completion  copy-from   arg              52          96  yes   Item number                            
completion  disabled    arg              52          96  yes   Defines whether item is ignored or used
completion  netmask     arg              52          95  yes   Network mask                           
completion  network     arg              52          96  yes   Network prefix                         
completion  ;           syntax-meta      52          40  no    end of command
