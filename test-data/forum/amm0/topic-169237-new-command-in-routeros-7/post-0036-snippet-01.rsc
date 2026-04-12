# Source: https://forum.mikrotik.com/t/new-command-in-routeros-7/169237/36
# Topic: New command in RouterOs 7
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put [/terminal/inkey]                                                   
# 97
:put [:convert from=byte-array to=raw {[/terminal/inkey]}]
# a
