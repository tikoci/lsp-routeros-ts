# 1970-01-01 00:00:00 by RouterOS 7.15.2
#
# model = RB960PGS
/interface bridge add admin-mac=**ELIDED** auto-mac=no comment=defconf name=bridge
/interface bridge port add bridge=bridge comment=defconf interface=ether1
/interface bridge port add bridge=bridge comment=defconf interface=ether2
/interface bridge port add bridge=bridge comment=defconf interface=ether3
/interface bridge port add bridge=bridge comment=defconf interface=ether4
/interface bridge port add bridge=bridge comment=defconf interface=ether5
/interface bridge port add bridge=bridge comment=defconf interface=sfp1
/ip neighbor discovery-settings set discover-interface-list=all
/ip address add address=192.168.88.1/24 comment=defconf interface=bridge
/system routerboard settings set auto-upgrade=yes
/tool mac-server set allowed-interface-list=all
/tool mac-server mac-winbox set allowed-interface-list=all
