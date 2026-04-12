# Source: https://forum.mikrotik.com/t/find-addresses-with-same-octets/168376/3
# Topic: find addresses with same octets
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put (1.1.1.1 in 1.0.0.0/8)
#true
:put (1.1.1.1 in 8.0.0.0/8)
#false
