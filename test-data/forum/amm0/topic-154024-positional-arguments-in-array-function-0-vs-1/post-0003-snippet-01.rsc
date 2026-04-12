# Source: https://forum.mikrotik.com/t/positional-arguments-in-array-function-0-vs-1/154024/3
# Topic: Positional Arguments in Array Function - $0 vs $1?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# global function to reassign
:global echo do={ :put "[ echo \$0=$0 \$1=$1 ]"; :return "$1"; }
:put [$echo "it works from echo"]

# array function to reassign
:global funarray [toarray ""];
:set ($funarray->"echo") do={ :put "[ (arr)->echo \$0=$0 \$1=$1 ]"; :return "$0"}
:put [($funarray->"echo") "it works from funarray"]


# reassign code of global $echo as array element
:set ($funarray->"aliasfn") $echo
{/terminal style error; :put [($funarray->"aliasfn") "1st arg is not out"]; /terminal style none}
:put [($funarray->"aliasfn") 0 "2nd arg to the caller"]
# ...only the "2nd arg" works - it's looking for $1 which is actually the 2nd calling arg

# reassign function from array and set it on a global
:global aliasfn
:set $aliasfn ($funarray->"aliasfn")
{/terminal style error; :put [($aliasfn) "1st arg is not output"]; /terminal style none}
:put [($aliasfn) 0 "2nd arg to the caller"]
# ...recall the orginal echo is looking for $1 in output, the array assignment loses the command
#    and why adding 0 above helps to make the 2nd arg be $1
