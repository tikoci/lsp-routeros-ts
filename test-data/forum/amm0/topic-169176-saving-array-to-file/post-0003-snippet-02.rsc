# Source: https://forum.mikrotik.com/t/saving-array-to-file/169176/3
# Topic: Saving array to file
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# tests...
{
:put "File contains: $[/file get diskarray contents ]"
:put "Array length $[:len $before] should be 2..."
:put "After writing and reading to disk..."
:put "...it's length is $[:len $after] (typeof: $[:typeof $after]) containing:"
:put $after
:put "or \t$[:tostr $after]\tafter :tostr"
:put "with field1 being: $($after->"field1")"
:put "with index 0 being: $($after->0)"
/file remove diskarray
}
