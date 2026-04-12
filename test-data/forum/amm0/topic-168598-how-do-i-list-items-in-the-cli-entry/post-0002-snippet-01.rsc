# Source: https://forum.mikrotik.com/t/how-do-i-list-items-in-the-cli-entry/168598/2
# Topic: How do I list items in the CLI entry?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:foreach item in=[/ip service find vrf=main] do={
    :put [/ip service get $item]
}
