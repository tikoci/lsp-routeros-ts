# Source: https://forum.mikrotik.com/t/a-few-undocumented-operators-that-are-kind-of-neat/163557/11
# Topic: A few undocumented operators that are kind of neat.
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put (>"text $1") 
    # output:     (. text  $1)
:put [(>"text $1")]
    # output:     text
