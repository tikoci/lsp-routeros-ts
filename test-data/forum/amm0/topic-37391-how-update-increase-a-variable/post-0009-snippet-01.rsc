# Source: https://forum.mikrotik.com/t/how-update-increase-a-variable/37391/9
# Topic: How update/increase a variable?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global x 0
:set x ($x + 1)
:put $x
# shows: 1
:set x ($x + 1)
:put $x
# shows: 2
