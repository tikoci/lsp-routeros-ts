# Source: https://forum.mikrotik.com/t/iterate-over-all-elements-of-an-array-of-unknown-dimension/163033/29
# Topic: iterate over all elements of an array of unknown dimension
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global a {"a"="top";"child"={"a"="inside"}}
:global b $a
:put [:typeof $b]
# array
:put ($b->"child")
# a=inside
:set ($b->"child") "changed"
:put ($b->"child")
# changed
:put ($a->"child")
#  a=inside
