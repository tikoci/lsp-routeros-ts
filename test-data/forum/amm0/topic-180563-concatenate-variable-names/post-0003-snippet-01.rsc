# Source: https://forum.mikrotik.com/t/concatenate-variable-names/180563/3
# Topic: concatenate variable names
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global hello 123
:global hello2 "$($hello)456"
:put $hello2
