# Source: https://forum.mikrotik.com/t/help-me-to-write-this-script/156350/4
# Topic: Help me to write this script
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:local Site "mt.lv"
:local IP [:resolve $Site]
/ip firewall address-list
:if ([:len [find address=$IP list="demo"]]=0) do={
	add address=$IP list="demo" comment="$Site"
}
