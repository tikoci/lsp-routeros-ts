# Source: https://forum.mikrotik.com/t/conditional-not-boolean-bug-with-onerror-new-in-7-13/172543/25
# Topic: `conditional not boolean` bug with :onerror (new in 7.13)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global x [:do {:put "a"; :put "b"; :put "c"}]
:put "tostr: $[:tostr $x] len: $[:len $x] typeof: $[:typeof $x] array0: $($x->0) array1: $($x->1)"

tostr: ;c 
len: 2 
typeof: array 
array0:  
array1: c
