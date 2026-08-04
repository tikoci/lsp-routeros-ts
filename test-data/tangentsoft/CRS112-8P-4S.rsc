# 1970-01-01 00:00:00 by RouterOS 7.15.3
#
# model = CRS112-8P-4S
/interface bridge add admin-mac=**ELIDED** auto-mac=no comment=defconf name=bridge
/port set 0 name=serial0
/interface bridge port add bridge=bridge comment=defconf interface=ether1
/interface bridge port add bridge=bridge comment=defconf interface=ether2
/interface bridge port add bridge=bridge comment=defconf interface=ether3
/interface bridge port add bridge=bridge comment=defconf interface=ether4
/interface bridge port add bridge=bridge comment=defconf interface=ether5
/interface bridge port add bridge=bridge comment=defconf interface=ether6
/interface bridge port add bridge=bridge comment=defconf interface=ether7
/interface bridge port add bridge=bridge comment=defconf interface=ether8
/interface bridge port add bridge=bridge comment=defconf interface=sfp9
/interface bridge port add bridge=bridge comment=defconf interface=sfp10
/interface bridge port add bridge=bridge comment=defconf interface=sfp11
/interface bridge port add bridge=bridge comment=defconf interface=sfp12
/ip address add address=192.168.88.1/24 comment=defconf interface=bridge network=192.168.88.0
