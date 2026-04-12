# Source: https://forum.mikrotik.com/t/bypass-script-errors-wrong-commands/131473/18
# Topic: bypass script errors/wrong commands
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:if ([:len [/system package find name~"wave2"]]=0 or [system package get [find name~"wave2"] disabled]=true) do={
[:parse ":do {:foreach i in=[/interface wireless find] do={:local LAN [/interface wireless get $i name];/interface bridge port add bridge=bridge interface=$LAN}}"];
}
