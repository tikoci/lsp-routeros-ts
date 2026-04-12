# Source: https://forum.mikrotik.com/t/v7-1rc7-development-is-released/153617/160
# Topic: v7.1rc7 [development] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/ip/dhcp-client/print
Flags: X, I, D - DYNAMIC
Columns: INTERFACE, USE-PEER-DNS, ADD-DEFAULT-ROUTE, STATUS, ADDRESS
#   INTERFACE         USE-PEER-DNS  ADD  STATUS  ADDRESS          
0 X vlan-internet-in  no            no                            
;;; internet detect
1 D vlan-internet-in  yes           yes  bound   10.11.12.13
