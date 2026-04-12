# Source: https://forum.mikrotik.com/t/example-of-automating-vlan-creation-removal-inspecting-using-mkvlan-friends/181480/1
# Topic: 🧐 example of automating VLAN creation/removal/inspecting using $mkvlan & friends...
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface vlan add comment="mkvlan 123" interface=bridge name=vlan123 vlan-id=123
/ip address add address=192.168.123.1/24 comment="mkvlan 123" disabled=no interface=vlan123 network=192.168.123.0
/ip pool add comment="mkvlan 123" name=vlan123 ranges=192.168.123.10-192.168.123.249
/ip dhcp-server add address-lists="" address-pool=vlan123 comment="mkvlan 123" disabled=no interface=vlan123 lease-script="" lease-time=30m n
ame=vlan123 use-radius=no
/ip dhcp-server network add address=192.168.123.0/24 caps-manager="" comment="mkvlan 123" dhcp-option="" dns-server=192.168.123.1 gateway=192
.168.123.1 !next-server ntp-server="" wins-server=""
/interface list member add comment="mkvlan 123" disabled=no interface=vlan123 list=LAN
/ip firewall address-list add address=192.168.123.0/24 comment="mkvlan 123" disabled=no dynamic=no list=vlan123
