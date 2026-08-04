# 1970-01-01 00:00:00 by RouterOS 7.15.2
#
# model = L41G-2axD
/interface bridge add admin-mac=**ELIDED** auto-mac=no comment=defconf name=bridge
/interface bridge port add bridge=bridge comment=defconf interface=ether1
/interface bridge port add bridge=bridge comment=defconf interface=ether2
/interface bridge port add bridge=bridge comment=defconf interface=ether3
/interface bridge port add bridge=bridge comment=defconf interface=ether4
/ip dhcp-client add interface=bridge
