# Source: https://forum.mikrotik.com/t/lte-gw/176936/3
# Topic: LTE-gw
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/routing/route/print detail 
Flags: X - disabled, F - filtered, U - unreachable, A - active; 
c - connect, s - static, r - rip, b - bgp, o - ospf, i - isis, d - dhcp, v - vpn, m - modem, a - ldp-address, l - ldp-mapping, g - slaac>
H - hw-offloaded; + - ecmp, B - blackhole 
 Am   afi=ip4 contribution=active dst-address=0.0.0.0/0 routing-table=main gateway=lte1 immediate-gw=lte1 distance=2 scope=30 
       target-scope=10 belongs-to="modem" 
       debug.fwp-ptr=0x20282120
