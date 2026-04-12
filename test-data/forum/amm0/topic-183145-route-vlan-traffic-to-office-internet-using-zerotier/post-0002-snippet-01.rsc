# Source: https://forum.mikrotik.com/t/route-vlan-traffic-to-office-internet-using-zerotier/183145/2
# Topic: Route VLAN traffic to office internet using zerotier
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# add new/2nd routing table
/routing/table/add name=ztoffice fib 

# route new table via remote ZT router
/ip/route/add gateway=10.172.17.21 routing-table=ztoffice check-gateway=ping

# route rule to send VLAN5 to Cudy ZT
/routing/rule/add interface=vlan5 action=lookup table=ztoffice
