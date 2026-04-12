# Source: https://forum.mikrotik.com/t/convert-any-text-to-unicode/164329/24
# Topic: Convert any text to UNICODE
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[u@rsc] > :put "something\nnext"
something
         next
[u@rsc] > :put "something\r\nnext"
something
next
