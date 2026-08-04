# 1970-01-01 00:00:00 by RouterOS 7.16.1
#
# model = CRS328-24P-4S+
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
/interface bridge port add bridge=bridge comment=defconf interface=ether9
/interface bridge port add bridge=bridge comment=defconf interface=ether10
/interface bridge port add bridge=bridge comment=defconf interface=ether11
/interface bridge port add bridge=bridge comment=defconf interface=ether12
/interface bridge port add bridge=bridge comment=defconf interface=ether13
/interface bridge port add bridge=bridge comment=defconf interface=ether14
/interface bridge port add bridge=bridge comment=defconf interface=ether15
/interface bridge port add bridge=bridge comment=defconf interface=ether16
/interface bridge port add bridge=bridge comment=defconf interface=ether17
/interface bridge port add bridge=bridge comment=defconf interface=ether18
/interface bridge port add bridge=bridge comment=defconf interface=ether19
/interface bridge port add bridge=bridge comment=defconf interface=ether20
/interface bridge port add bridge=bridge comment=defconf interface=ether21
/interface bridge port add bridge=bridge comment=defconf interface=ether22
/interface bridge port add bridge=bridge comment=defconf interface=ether23
/interface bridge port add bridge=bridge comment=defconf interface=ether24
/interface bridge port add bridge=bridge comment=defconf interface=sfp-sfpplus1
/interface bridge port add bridge=bridge comment=defconf interface=sfp-sfpplus2
/interface bridge port add bridge=bridge comment=defconf interface=sfp-sfpplus3
/interface bridge port add bridge=bridge comment=defconf interface=sfp-sfpplus4
/ip address add address=192.168.88.1/24 comment=defconf interface=bridge network=192.168.88.0
