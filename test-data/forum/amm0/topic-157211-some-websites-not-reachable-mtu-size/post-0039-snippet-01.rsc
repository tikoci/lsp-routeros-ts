# Source: https://forum.mikrotik.com/t/some-websites-not-reachable-mtu-size/157211/39
# Topic: Some Websites Not Reachable (MTU size?)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface/vlan/print proplist=vlan-id,name,mtu,l2mtu
Flags: R - RUNNING
Columns: VLAN-ID, NAME, MTU, L2MTU
#   VLAN-ID  NAME                 MTU  L2MTU
0 R      22  vlan22-lan-general  1500   1510

:put [/system/resource/get version]
7.3beta33 (testing)
:put [/system/resource/get board-name]
RB5009UG+S+
