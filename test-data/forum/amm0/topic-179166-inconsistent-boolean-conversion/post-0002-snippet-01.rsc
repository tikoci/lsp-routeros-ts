# Source: https://forum.mikrotik.com/t/inconsistent-boolean-conversion/179166/2
# Topic: Inconsistent boolean conversion
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put [:typeof [:tobool "anystring"]]
#  nil 
:put [:typeof [:tobool "false"]]    
#  nul
