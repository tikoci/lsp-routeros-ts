# Source: https://forum.mikrotik.com/t/v7-22beta-development-is-released/267611/91
# Topic: V7.22beta [development] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/routing/rule/print
Flags: X - disabled, I - inactive; * - default 
 0  * action=mangle 
 1  * action=lookup vrf 
 2  * action=unreachable vrf 
 3  * action=lookup table=local 
 4  * action=lookup table=main
