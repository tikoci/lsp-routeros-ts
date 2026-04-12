# Source: https://forum.mikrotik.com/t/built-in-function-library/117288/106
# Topic: Built in function library
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global mystr "blah, blah, blah"
:global matches [:regex match=/blah/ from=$mystr  multiline greedy global]
:put [:typeof $matches]
# array
:put $matches                       
# blah;blah;blah
:put [:len $matches] 
# 3
