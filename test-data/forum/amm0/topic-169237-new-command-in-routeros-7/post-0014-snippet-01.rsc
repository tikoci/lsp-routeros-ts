# Source: https://forum.mikrotik.com/t/new-command-in-routeros-7/169237/14
# Topic: New command in RouterOs 7
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global userinput [/terminal/ask preinput="preinput>" prompt="Some text that in prompt=" ]    
# Some text that in prompt=
# preinput>test
:put $userinput
# test
