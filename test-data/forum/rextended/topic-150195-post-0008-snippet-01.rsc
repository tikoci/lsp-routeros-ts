# Source: https://forum.mikrotik.com/t/wan-load-balancing-between-2-isps-one-with-cgnat-and-another-in-bridge-mode-real-ipv4-address/150195/8
# Post author: @rextended
# Extracted from: code-block

:global isp1gateway 177.142.96.44
:global isp2gateway 192.168.0.254

/ip dns
set servers=1.1.1.1,8.8.8.8

/ip route
add comment="A - 1.1.1.1 must be reachable only by ISP1" distance=1 dst-address=1.1.1.1/32 gateway=177.142.96.44 scope=10 target-scope=11
add comment="B - Recursive ping 1.1.1.1" distance=10 dst-address=0.0.0.0/0 gateway=1.1.1.1 scope=30 target-scope=12 check-gateway=ping
add comment="C - ISP2 is the alternative gateway" distance=20 dst-address=0.0.0.0/0 gateway=192.168.0.254 scope=30 target-scope=11
