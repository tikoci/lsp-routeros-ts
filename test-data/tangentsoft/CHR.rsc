# 1970-01-01 00:00:00 by RouterOS 7.15.3
/interface ethernet set [ find default-name=ether1 ] disable-running-check=no
/interface wireless security-profiles set [ find default=yes ] supplicant-identity=MikroTik
/ip dhcp-client add interface=ether1
