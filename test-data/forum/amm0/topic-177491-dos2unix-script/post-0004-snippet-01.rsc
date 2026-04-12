# Source: https://forum.mikrotik.com/t/dos2unix-script/177491/4
# Topic: dos2unix script
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put [:convert from=raw to=hex "0\r\n0\r\n"]          
# 300d0a300d0a
:put [:convert from=raw to=hex "0\n0\n"]      
# 300a300a
