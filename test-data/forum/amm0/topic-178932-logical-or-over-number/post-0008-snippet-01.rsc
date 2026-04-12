# Source: https://forum.mikrotik.com/t/logical-or-over-number/178932/8
# Topic: logical "or" over number
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put [:convert from=hex to=bit-array-lsb "EF"] 
# 1;1;1;1;0;1;1;1
:put [:convert from=hex to=bit-array-msb "EF"] 
# 1;1;1;0;1;1;1;1
:put [:convert from=byte-array to=bit-array-lsb {239}]   
# 1;1;1;1;0;1;1;1
:put [:convert from=byte-array to=bit-array-msb {239}]      
# 1;1;1;0;1;1;1;1
