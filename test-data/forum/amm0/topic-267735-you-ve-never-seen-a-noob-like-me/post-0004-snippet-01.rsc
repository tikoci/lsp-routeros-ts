# Source: https://forum.mikrotik.com/t/youve-never-seen-a-noob-like-me/267735/4
# Topic: You've Never Seen a Noob Like Me
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface vlan add name=vlan2 vlan-id=2 interface=([/interface/bridge/find]->0)
/ip address add address=192.168.2.1/24 interface=vlan2
/ip pool add name=vlan2 ranges=192.168.2.2-192.168.2.254
/ip dhcp-server add address-pool=vlan2 interface=vlan2 name=vlan2
/ip dhcp-server network add address=192.168.2.0/24 dns-server=192.168.2.1 gateway=192.168.2.1
