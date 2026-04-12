# Source: https://forum.mikrotik.com/t/mikrotik-atl-lte18-in-bridged-mode/176329/6
# Topic: Mikrotik ATL LTE18 in Bridged Mode
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface/bridge/set [find name=bridge] vlan-filtering=yes
/interface/vlan add vlan-id=301 name=lte-passthrough bridge=bridge
/interface/lte/apn set [find name=default] passthrough-interface=lte-passthrough
/interface/bridge/vlan add vlan-ids=301 tagged=bridge,ether1
/interface/bridge/vlan add vlan-ids=1 untagged=bridge,ether1
