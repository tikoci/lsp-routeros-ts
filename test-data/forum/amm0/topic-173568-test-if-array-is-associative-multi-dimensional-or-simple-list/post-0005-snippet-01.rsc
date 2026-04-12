# Source: https://forum.mikrotik.com/t/test-if-array-is-associative-multi-dimensional-or-simple-list/173568/5
# Topic: Test if array is associative, multi-dimensional, or simple list
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global x [:toarray ""]
:set ($x->9) 9
:put [:len $x]
:put [:typeof ($x->0)]
:put [:typeof ($x->10)]
:put $x
