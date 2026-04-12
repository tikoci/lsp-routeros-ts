# Source: https://forum.mikrotik.com/t/multiple-wan-the-third-wan-on-sfp3/174873/22
# Topic: Multiple WAN - The Third WAN on sfp3
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface bridge set [find name=BridgeLAN] comment=defconf
/interface list member set [find list=LAN interface=BridgeLAN] comment=defconf
/ip address set [find address=192.168.88.1/24] comment=defconf
