# Source: https://forum.mikrotik.com/t/unexpected-behavior-when-finding-by-variable-value/175598/5
# Topic: Unexpected behavior when finding by variable value
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global fn2 do={
   :local address
   :return $address
}
:put [$fn2 address=1.1.1.1]
#output:  (nothing)
