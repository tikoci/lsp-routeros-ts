# Source: https://forum.mikrotik.com/t/built-in-function-library/117288/106
# Topic: Built in function library
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global replacedstring [:regex find="blah"  replace="hello" from=$mystr]
:put [:typeof $replacedstring]
# string
