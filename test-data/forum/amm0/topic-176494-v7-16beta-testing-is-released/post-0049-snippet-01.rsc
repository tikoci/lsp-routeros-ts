# Source: https://forum.mikrotik.com/t/v7-16beta-testing-is-released/176494/49
# Topic: v7.16beta [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface/bridge/vlan> /interface/bridge/vlan/print where vlan-ids=42
Flags: D - DYNAMIC
Columns: BRIDGE, VLAN-IDS, CURRENT-TAGGED, CURRENT-UNTAGGED
 #   BRIDGE  VLAN-IDS  CURRENT-TAGGED  CURRENT-UNTAGGED
;;; added by vlan on bridge
 8 D bridge        42  bridge                          
;;; added by pvid
11 D bridge        42                  ether10
