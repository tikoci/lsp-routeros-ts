# Source: https://forum.mikrotik.com/t/using-ai-to-help-configuring-routeros-and-scripting/183452/36
# Topic: Using AI to help configuring RouterOS and scripting
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global badconfig "/ip address
add address=100.1.1.1/29 interface=ether1
add address=100.1.1.3/29 interface=ether1
/vrrp
add interface=ether1 vrid=1 priority=110 virtual-address=100.1.1.3
/ip route
add gateway=100.1.1.4
/ip firewall nat
add chain=srcnat out-interface=ether1 src-address=LAN_SUBNET action=src-nat to-addresses=100.1.1.3
/connection tracking
set enabled=yes
/connection tracking sync
set enabled=yes"
