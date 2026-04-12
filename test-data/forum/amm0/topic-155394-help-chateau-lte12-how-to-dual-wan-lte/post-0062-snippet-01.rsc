# Source: https://forum.mikrotik.com/t/help-chateau-lte12-how-to-dual-wan-lte/155394/62
# Topic: Help Chateau LTE12 how to dual wan lte
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[admin@MikroTik] > /ip/address/print
Flags: D - DYNAMIC
Columns: ADDRESS, NETWORK, INTERFACE
#   ADDRESS           NETWORK        INTERFACE
0   192.168.10.1/24   192.168.10.0   bridge1  
1 D 192.168.0.100/24  192.168.0.0    lte2     
2 D 100.91.21.150/32  100.91.21.150  lte1     
[admin@MikroTik] > /ip/route/print
Flags: D - DYNAMIC; A - ACTIVE; c, s, d, m, y - COPY; + - ECMP
Columns: DST-ADDRESS, GATEWAY, DISTANCE
[b]#      DST-ADDRESS       GATEWAY        DISTANCE
  DAm+ 0.0.0.0/0         lte1                  2
  DAd+ 0.0.0.0/0         192.168.0.254         2[/b]
  DAc  100.91.21.150/32  lte1                  0
  DAc  192.168.0.0/24    lte2                  0
  DAc  192.168.10.0/24   bridge1               0
0  As  0.0.0.0/0         lte1                  1
[b]1  As  0.0.0.0/0         lte2                  1[/b]
