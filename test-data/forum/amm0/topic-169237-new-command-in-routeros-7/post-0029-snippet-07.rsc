# Source: https://forum.mikrotik.com/t/new-command-in-routeros-7/169237/29
# Topic: New command in RouterOs 7
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/console/inspect request=completion input="/console/inspect request="

Columns: TYPE, COMPLETION, STYLE, OFFSET, PREFERENCE, SHOW, TEXT
TYPE        COMPLETION  STYLE        OFFSET  PREFERENCE  SHOW  TEXT                         
completion              none             25  -1          no    whitespace                   
completion              none             25  64          no                                 
completion  [           syntax-meta      25  75          no    start of command substitution
completion  (           syntax-meta      25  75          no    start of expression          
completion  $           syntax-meta      25  75          no    substitution                 
completion  "           syntax-meta      25  75          no    start of quoted string       
completion  self        none             25  96          yes                                
completion  child       none             25  96          yes                                
completion  completion  none             25  96          yes                                
completion  highlight   none             25  96          yes                                
completion  syntax      none             25  96          yes                                
completion  error       none             25  96          yes
