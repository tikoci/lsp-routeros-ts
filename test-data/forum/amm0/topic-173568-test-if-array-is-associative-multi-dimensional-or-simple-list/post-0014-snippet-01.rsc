# Source: https://forum.mikrotik.com/t/test-if-array-is-associative-multi-dimensional-or-simple-list/173568/14
# Topic: Test if array is associative, multi-dimensional, or simple list
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:foreach k,v in=$ar do={
        :if ([:typeof $v]="array") do={
            :if ([:typeof "$k"]="num") do={:put "list"} else={:put "map"}
         }
}
