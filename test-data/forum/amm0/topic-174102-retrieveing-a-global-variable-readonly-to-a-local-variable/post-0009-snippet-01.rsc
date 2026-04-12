# Source: https://forum.mikrotik.com/t/retrieveing-a-global-variable-readonly-to-a-local-variable/174102/9
# Topic: Retrieveing a global variable readonly to a local variable
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/system/script/add name=staticUrl source={ :return "http://example.com" } dont-require-permissions=yes

:put [/system/script/run staticUrl]          
# http://example.com

#or actually using a local:
{ :local staticUrl [/system/script/run staticUrl]; :put $staticUrl }
# http://example.com
