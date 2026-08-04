# 1970-01-01 00:00:00 by RouterOS 7.15.3
#
# model = CCR2116-12G-4S+
/port set 0 name=serial0
/ip address add address=192.168.88.1/24 comment=defconf interface=ether13 network=192.168.88.0
/system routerboard settings set enter-setup-on=delete-key
