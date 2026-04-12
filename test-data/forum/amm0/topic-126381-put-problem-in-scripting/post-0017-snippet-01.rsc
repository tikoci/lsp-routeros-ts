# Source: https://forum.mikrotik.com/t/put-problem-in-scripting/126381/17
# Topic: ":put" problem in scripting
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global strarr {"abc"; "def"}
:put [len $strarr]
# 2
:put [typeof $strarr]
array
:put "strarr=$strarr"
#strarr=abc;strarr=def
:global strstrarr "strarr=$strarr"
:put [len $strstrarr]
#2
:put [typeof $strstrarr]
#array
:put $strstrarr
#strarr=abc;strarr=def
:put ($strstrarr->0)
#strarr=abc
:put "onemorelevel=$strstrarr"
#onemorelevel=strarr=abc;onemorelevel=strarr=def
