# Source: https://forum.mikrotik.com/t/example-of-automating-vlan-creation-removal-inspecting-using-mkvlan-friends/181480/1
# Topic: 🧐 example of automating VLAN creation/removal/inspecting using $mkvlan & friends...
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

starting VLAN network creation for 192.168.123.0/24 using id 123 ...
- adding vlan123 interface on bridge using vlan-id=123
- assigning IP address of 192.168.123.1/24 for vlan123
- adding IP address pool 192.168.123.10-192.168.123.249 for DHCP
- adding dhcp-server vlan123
- adding DHCP /24 network using gateway=192.168.123.1 and dns-server=192.168.123.1
- add VLAN network to interface LAN list
- create FW address-list for VLAN network for 192.168.123.0/24
* NOTE: in 7.16+, the VLAN 123 is dynamically added to /interface/bridge/vlans with tagged=bridge
thus making an access port ONLY involves setting pvid=123 on a /interface/bridge/port
* EX:   So to make 'ether3' an access point, only the following additional command is:
/interface/bridge/port set [find interface=ether3] pvid=123 frame-types=allow-only-untagged
VLAN network created for 192.168.123.0/24 for vlan-id=123
