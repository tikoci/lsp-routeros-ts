# Source: https://forum.mikrotik.com/t/v7-13-5-stable-is-released/171923/878
# Topic: v7.13.5 [stable] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global multilineString "hello\nworld\nhello world"
:global hellos [:grep ":put \"$multilineString\"" pattern="hello.*" as-array] 
:put $hellos
# hello;hello world
:put [:len $hellos]
# 2
