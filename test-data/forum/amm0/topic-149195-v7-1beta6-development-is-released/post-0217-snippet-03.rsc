# Source: https://forum.mikrotik.com/t/v7-1beta6-development-is-released/149195/217
# Topic: v7.1beta6 [development] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# vlan for ECMP route
/interface/vlan/add name=vlan-ecmp2 vlan-id=2 interface=bridge comment=ecmp2
/ip/address/add interface=vlan-ecmp2 address=203.0.113.1/24 comment=ecmp2
# dchp-server on ECMP route
/ip/dhcp-server/network/add address=203.0.113.0/24 gateway=203.0.113.1 comment=ecmp2
/ip/pool/add name=ecmp2 ranges=203.0.113.101-203.0.113.199 comment=ecmp2
/ip/dhcp-server/add address-pool=ecmp2 name=ecmp2 interface=vlan-ecmp2 disabled=no
# with default firewall, adding to LAN interface list will do NAT
/interface/list/member/add interface=vlan-ecmp2 list=LAN
# many ways to do this part, a policy rule seemed simple to show this working (NOTE: v6 had this under "/ip route rule")
/routing/rule/add src-address=203.0.113.0/24 table=ecmp2 comment=ecmp2
