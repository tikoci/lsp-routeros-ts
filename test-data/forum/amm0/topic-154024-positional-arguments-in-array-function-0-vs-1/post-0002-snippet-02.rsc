# Source: https://forum.mikrotik.com/t/positional-arguments-in-array-function-0-vs-1/154024/2
# Topic: Positional Arguments in Array Function - $0 vs $1?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global hello do={:put "$1 $prefix $2"}
[$hello hello world prefix=mx]
#>>                                             hello mx world
[$hello prefix=mrs hello world]
#>>                                             hello mrs world
[$hello hello prefix=mr world]
#>>                                             hello mr world
