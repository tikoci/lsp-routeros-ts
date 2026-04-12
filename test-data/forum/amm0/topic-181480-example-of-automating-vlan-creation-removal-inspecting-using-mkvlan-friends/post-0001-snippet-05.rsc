# Source: https://forum.mikrotik.com/t/example-of-automating-vlan-creation-removal-inspecting-using-mkvlan-friends/181480/1
# Topic: 🧐 example of automating VLAN creation/removal/inspecting using $mkvlan & friends...
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

- /interface/vlan
[
{
".id": "*138",
"arp": "enabled",
"arp-timeout": "auto",
"comment": "mkvlan 123",
"interface": "bridge",
"l2mtu": 1588,
"loop-protect": "default",
"loop-protect-disable-time": "1970-01-01 00:05:00",
"loop-protect-send-interval": "1970-01-01 00:00:05",
"loop-protect-status": "off",
"mac-address": "74:4D:28:38:B3:CD",
"mtu": 1500,
"mvrp": false,
"name": "vlan123",
"use-service-tag": false,
"vlan-id": 123
}
]
- /ip/address
[
{
".id": "*120",
"actual-interface": "vlan123",
"address": "192.168.123.1/24",
"comment": "mkvlan 123",
"interface": "vlan123",
"network": "192.168.123.0"
}
]
- /ip/pool
[
{
".id": "*13",
"comment": "mkvlan 123",
"name": "vlan123",
"ranges": [
"192.168.123.10-192.168.123.249"
]
}
]
- /ip/dhcp-server
[
{
".id": "*F",
"address-lists": [],
"address-pool": "vlan123",
"comment": "mkvlan 123",
"interface": "vlan123",
"lease-script": "",
"lease-time": "1970-01-01 00:30:00",
"name": "vlan123",
"use-radius": "no"
}
]
- /ip/dhcp-server/network
[
{
".id": "*F",
"address": "192.168.123.0/24",
"caps-manager": [],
"comment": "mkvlan 123",
"dhcp-option": [],
"dns-server": "192.168.123.1",
"gateway": [
"192.168.123.1"
],
"ntp-server": [],
"wins-server": []
}
]
- /interface/list/member
[
{
".id": "*6F",
"comment": "mkvlan 123",
"dynamic": false,
"interface": "vlan123",
"list": "LAN"
}
]
- /ip firewall address-list
[
{
".id": "*1D",
"address": "192.168.123.0/24",
"comment": "mkvlan 123",
"creation-time": "2025-01-24 16:31:46",
"dynamic": false,
"list": "vlan123"
}
]
