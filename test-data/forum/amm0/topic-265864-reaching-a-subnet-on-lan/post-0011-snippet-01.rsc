# Source: https://forum.mikrotik.com/t/reaching-a-subnet-on-lan/265864/11
# Topic: Reaching a subnet on LAN
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/ip/address/add address=192.168.0.99/24 interface=bridge1
/ip/firewall/nat/add chain=srcnat action=masquerade dst-address=192.168.0.0/24
