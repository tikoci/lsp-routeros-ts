# Source: https://forum.mikrotik.com/t/a-few-undocumented-operators-that-are-kind-of-neat/163557/11
# Topic: A few undocumented operators that are kind of neat.
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global fn do={:put "$1 $2"}
:put $fn
    # output:      ;(evl (evl /putmessage=(. $1   $2)))
:put [:typeof $fn]
    # output:      array
:put [:len $fn]
    # output:      2 
:put [:typeof ($fn->1)] 
    # output:      code
