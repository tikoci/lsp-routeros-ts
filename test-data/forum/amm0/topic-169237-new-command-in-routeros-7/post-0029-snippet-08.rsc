# Source: https://forum.mikrotik.com/t/new-command-in-routeros-7/169237/29
# Topic: New command in RouterOs 7
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/console/inspect request=completion input="/ip/add" 

Columns: TYPE, COMPLETION, STYLE, OFFSET, PREFERENCE, SHOW, TEXT
TYPE        COMPLETION  STYLE        OFFSET  PREFERENCE  SHOW  TEXT                    
completion  address     dir               4  96          yes   Address management      
completion  /           dir               7  95          yes   top of command hierarchy
completion              none              7  -1          no    whitespace              
completion  {           syntax-meta       7  40          no    start of command block  
completion  ;           syntax-meta       7  40          no    end of command
