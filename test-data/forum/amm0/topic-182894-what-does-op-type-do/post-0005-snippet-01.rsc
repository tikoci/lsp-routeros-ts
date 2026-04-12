# Source: https://forum.mikrotik.com/t/what-does-op-type-do/182894/5
# Topic: What does op type (>[ ... ]) do?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# version 1
{
    :local x 1
    :local fn do={:put $x}
    $fn
}
# prints nothing, since $x is not in scope

# version 2
# vs, using (>[]) which creates a function that returns a code data-type, and prints "2"
{
    :local x2 2
    :local fn2 (>[:put $x2])
    $fn2
}
2
