# 1970-01-01 00:00:00 by RouterOS 7.15.3
#
# model = CRS212-1G-10S-1S+
/interface bridge add admin-mac=**ELIDED** auto-mac=no comment=defconf name=bridge
/port set 0 name=serial0
/interface bridge port add bridge=bridge comment=defconf interface=ether1
/interface bridge port add bridge=bridge comment=defconf interface=sfp1
/interface bridge port add bridge=bridge comment=defconf interface=sfp2
/interface bridge port add bridge=bridge comment=defconf interface=sfp3
/interface bridge port add bridge=bridge comment=defconf interface=sfp4
/interface bridge port add bridge=bridge comment=defconf interface=sfp5
/interface bridge port add bridge=bridge comment=defconf interface=sfp6
/interface bridge port add bridge=bridge comment=defconf interface=sfp7
/interface bridge port add bridge=bridge comment=defconf interface=sfp8
/interface bridge port add bridge=bridge comment=defconf interface=sfp9
/interface bridge port add bridge=bridge comment=defconf interface=sfp10
/interface bridge port add bridge=bridge comment=defconf interface=sfpplus1
/ip address add address=192.168.88.1/24 comment=defconf interface=bridge network=192.168.88.0
