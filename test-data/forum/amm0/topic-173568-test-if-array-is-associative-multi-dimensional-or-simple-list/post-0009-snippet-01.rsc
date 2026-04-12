# Source: https://forum.mikrotik.com/t/test-if-array-is-associative-multi-dimensional-or-simple-list/173568/9
# Topic: Test if array is associative, multi-dimensional, or simple list
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put [:serialize {a=123} to=json]
{"a":123}
:put [:deserialize "{ \"a\": 123 }" from=json ]                 
a=123
