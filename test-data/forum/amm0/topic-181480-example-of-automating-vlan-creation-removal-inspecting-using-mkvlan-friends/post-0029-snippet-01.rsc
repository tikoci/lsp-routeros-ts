# Source: https://forum.mikrotik.com/t/example-of-automating-vlan-creation-removal-inspecting-using-mkvlan-friends/181480/29
# Topic: 🧐 example of automating VLAN creation/removal/inspecting using $mkvlan & friends...
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# 2025-02-01 06:02:17 by RouterOS 7.18beta4
# model = RB760iGS
/interface bridge
add add-dhcp-option82=yes admin-mac=B8:69:F4:01:81:18 auto-mac=no comment="main VLAN bridge" dhcp-snooping=yes mvrp=yes name=bridge1 port-cost-mode=short protocol-mode=mstp vlan-filtering=yes
/interface bridge port
add bridge=bridge1 interface=ether2 internal-path-cost=10 path-cost=10 pvid=10 trusted=yes
add bridge=bridge1 interface=ether3 internal-path-cost=10 path-cost=10 pvid=8 trusted=yes
add bridge=bridge1 frame-types=admit-only-vlan-tagged interface=ether4 internal-path-cost=10 path-cost=10 pvid=6 tag-stacking=yes trusted=yes
add bridge=bridge1 ingress-filtering=no interface=ether5 internal-path-cost=10 path-cost=10 pvid=8 tag-stacking=yes trusted=yes
add bridge=bridge1 ingress-filtering=no interface=sfp1 internal-path-cost=10 path-cost=10
add bridge=bridge1 frame-types=admit-only-untagged-and-priority-tagged interface=ether1 internal-path-cost=10 path-cost=10 pvid=8 trusted=yes
/interface bridge vlan
add bridge=bridge1 tagged=bridge1,ether4 untagged=sfp1 vlan-ids=8
add bridge=bridge1 tagged=bridge1 untagged=sfp1 vlan-ids=6
add bridge=bridge1 tagged=bridge1,ether2 vlan-ids=10
add bridge=bridge1 comment="added by \$mktrunk" tagged=ether4,sfp1 vlan-ids=2001
add bridge=bridge1 comment="added by \$mktrunk" tagged=ether2,ether5 vlan-ids=3001
