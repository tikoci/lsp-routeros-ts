# Source: https://forum.mikrotik.com/t/positional-arguments-in-array-function-0-vs-1/154024/1
# Topic: Positional Arguments in Array Function - $0 vs $1?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global hello
:set $hello do={:put "$0 $1"}
$hello world
#>>            $hello world

:global greetings [toarray ""]
:set ($greetings->"hello") do={:put "hello $1 "}
[($greetings->"hello") world]
#>>                                     hello
{ /terminal style error; put "expected: 'hello world' not just 'hello' string"; /terminal style none }   

# use $0 instead, works: 
:set ($greetings->"hello") do={:put "hello $0"}
[($greetings->"hello") world]
#>>                                       hello world
