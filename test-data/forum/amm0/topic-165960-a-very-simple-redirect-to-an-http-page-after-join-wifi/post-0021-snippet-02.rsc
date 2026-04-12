# Source: https://forum.mikrotik.com/t/a-very-simple-redirect-to-an-http-page-after-join-wifi/165960/21
# Topic: A very simple redirect (to an http page) after join WiFi
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# add DHCP Option 114 stuff...
/ip dhcp-server option add code=114 name=nodered value="'https://nodered.example.link:1880/api'"
/ip dhcp-server option sets add name=NODERED options=nodered

# using Virtual AP for testing...
/interface wifiwave2 add configuration.mode=ap .ssid=NodeRED disabled=nomaster-interface=wifi1 name=wifi3

# create new VLAN for the "NodeRED" SSID above...
/interface bridge [find] vlan-filtering=yes
/interface vlan add interface=bridge name=vlan114 vlan-id=114
/interface bridge port add bridge=bridge interface=wifi3 pvid=114
/interface bridge vlan add bridge=bridge tagged=bridge vlan-ids=114
/interface list member add interface=vlan114 list=LAN
/ip address add address=10.1.14.1/24 interface=vlan114 network=10.1.14.0

# now add a new DHCP server that uses the Option 114 that points to NodeRED
/ip pool add name=dhcp_pool2 ranges=10.1.14.2-10.1.14.254
/ip dhcp-server add address-pool=dhcp_pool2 dhcp-option-set=NODERED interface=vlan114 name=dhcp2
/ip dhcp-server network add address=10.1.14.1/24 dns-server=10.1.14.1 gateway=10.1.14.1

# Add static DNS to point to the NodeRED's IP address, that matches the DNS name used the HTTPS certificate
# Mikrotik DNS must used resolve the HTTPS name to the private NodeRED IP address, in my case that's 192.168.100.207 
/ip dns set allow-remote-requests=yes
/ip dns static add address=192.168.100.207 name=nodered.example.link"
