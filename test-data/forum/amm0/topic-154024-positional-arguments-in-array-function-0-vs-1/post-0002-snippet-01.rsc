# Source: https://forum.mikrotik.com/t/positional-arguments-in-array-function-0-vs-1/154024/2
# Topic: Positional Arguments in Array Function - $0 vs $1?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global greetings [toarray ""]
:set ($greetings->"hello") do={:put "$0 $prefix $1"}
[($greetings->"hello") hello world prefix=mx]
#>>                                             hello mx world
[($greetings->"hello") prefix=mrs hello world]
#>>                                             hello mrs world
[($greetings->"hello") hello prefix=mr world]
#>>                                             hello mr world
