# Source: https://forum.mikrotik.com/t/functions-and-function-parameters/68159/57
# Topic: Functions and function parameters
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local fn1 do={:put "in fn1"}
:local fn2 do={:put "in fn2"}
:local fn12 do={ $fn1 $fn2 }
$fn12
:put "will output nothing, since \$fn1 and \$fn2 are NOT available inside the \$fn12 function"
}
