# Source: https://forum.mikrotik.com/t/decimals/21737/10
# Topic: Decimals ?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put [$tofloat 0]
                 1000::
:put [$tofloat 1.1]
                   1000:1::1
:put [$tofloat -1.1]
                    1001:1::1
:put [$tofloat 4343.1344]
                         1000:540::10f7
