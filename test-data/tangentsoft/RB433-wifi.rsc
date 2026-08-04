# 1970-01-01 00:00:00 by RouterOS 7.15.3
#
# model = RB433
/interface wireless set [ find default-name=wlan1 ] ssid=MikroTik
/interface wireless security-profiles set [ find default=yes ] supplicant-identity=MikroTik
/port set 0 name=serial0
/ip address add address=192.168.88.1/24 comment=defconf interface=ether1 network=192.168.88.0
