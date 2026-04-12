# Source: https://forum.mikrotik.com/t/new-command-in-routeros-7/169237/8
# Topic: New command in RouterOs 7
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put [:convert "abcd" to=base64]                  
# YWJjZA==
:put [:convert from=base64 "YWJjZA==" ]                  
# abcd
