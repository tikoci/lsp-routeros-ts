# Source: https://forum.mikrotik.com/t/vrrp-on-wan/166698/2
# Topic: VRRP on WAN
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global "vrrp-public-IP-address" 2.2.2.2

/ip firewall nat
add action=src-nat chain=srcnat comment="enabled if master" disabled=yes out-ipsec-policy=out,none interface=ether1 to-addresses=$"vrrp-public-IP-address"
add action=masquerade chain=srcnat comment="defconf: masquerade" ipsec-policy=out,none out-interface-list=WAN

/interface vrrp add interface=ether1 name=vrrp-wan \
    on-backup="/ip firewall nat disable [find comment~\"if master\"] " \
    on-master="/ip firewall nat enable [find comment~\"if master\"] "
