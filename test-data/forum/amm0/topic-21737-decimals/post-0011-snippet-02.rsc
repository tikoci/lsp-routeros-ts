# Source: https://forum.mikrotik.com/t/decimals/21737/11
# Topic: Decimals ?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:import fakefloat
:global myfloat [$tofloat -10.1]
:put [$fromfloat $myfloat]
# -10.1
