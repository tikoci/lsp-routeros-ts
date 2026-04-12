# Source: https://forum.mikrotik.com/t/using-wifiwave2-to-bridge-two-audience-wirelessly-thoughts-4-address-mode/153357/3
# Topic: Using WifiWave2 to bridge two Audience wirelessly, thoughts? == 4-address mode
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[skyfi@M172-Rizi] /interface/vxlan> export
# nov/17/2021 17:43:05 by RouterOS 7.1rc6
# model = RBD25GR-5HPacQD2HPnD
/interface vxlan
add group=239.11.37.100 interface=wifi-MeshStation mtu=1450 name=\
    vxlan-skybridge port=8472 vni=100
[skyfi@M172-Rizi] /interface/vxlan> print detail 
Flags: X - disabled, R - running 
 0 R name="vxlan-skybridge" mtu=1450 mac-address=EA:D5:A5:1A:C5:73 arp=enabled 
     arp-timeout=auto loop-protect=default loop-protect-status=off 
     loop-protect-send-interval=5s loop-protect-disable-time=5m vni=100 
     group=239.11.37.100 interface=wifi-MeshStation port=8472 
[skyfi@M172-Rizi] /interface/vxlan> set 0 mtu=1500
failure: could not set mtu
[skyfi@M172-Rizi] /interface/vxlan> set 0 mtu=1451
failure: could not set mtu
[skyfi@M172-Rizi] /interface/vxlan> set 0 mtu=1449
[skyfi@M172-Rizi] /interface/vxlan> set 0 mtu=1450
