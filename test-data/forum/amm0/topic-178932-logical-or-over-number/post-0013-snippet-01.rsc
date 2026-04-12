# Source: https://forum.mikrotik.com/t/logical-or-over-number/178932/13
# Topic: logical "or" over number
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global invbits [$invBinaryString "1010101111101"]          
:put ($invbits->0)                               
#false
