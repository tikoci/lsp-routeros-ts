# Source: https://forum.mikrotik.com/t/v7-17beta-testing-is-released/179003/55
# Topic: v7.17beta [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

routing/route/print where afi~"ip6" 
Flags: U - UNREACHABLE, A - ACTIVE; c - CONNECT, d - DHCP; H - HW-OFFLOADED; B - BLACKHOLE
Columns: DST-ADDRESS, GATEWAY, AFI, DISTANCE, SCOPE, TARGET-SCOPE, IMMEDIATE-GW
     DST-ADDRESS                  GATEWAY           AFI  DISTANCE  SCOPE  TARGET-SCOPE  IMMEDIATE-GW    
Ac   ::1/128                      lo                ip6         0     10             5  lo
