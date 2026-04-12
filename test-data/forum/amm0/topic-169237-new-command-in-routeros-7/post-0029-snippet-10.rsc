# Source: https://forum.mikrotik.com/t/new-command-in-routeros-7/169237/29
# Topic: New command in RouterOs 7
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/console/inspect request=completion input="set" path=ip,address

Columns: TYPE, COMPLETION, STYLE, OFFSET, PREFERENCE, SHOW, TEXT
TYPE        COMPLETION  STYLE        OFFSET  PREFERENCE  SHOW  TEXT                  
completion  set         cmd               0          96  yes   Change item properties
completion              none              3          80  no    whitespace            
completion  ;           syntax-meta       3          40  no    end of command
