# Source: https://forum.mikrotik.com/t/wan-load-balancing-between-2-isps-one-with-cgnat-and-another-in-bridge-mode-real-ipv4-address/150195/2
# Post author: @rextended
# Extracted from: code-block

:global isp1gateway 177.142.96.44
:global isp2gateway 192.168.0.254

/ip dns
set servers=1.1.1.1,8.8.8.8

/ip route
add comment="A - 1.1.1.1 must be reachable only from ISP1" distance=1 dst-address=1.1.1.1/32 gateway=$isp1gateway scope=10
add comment="B - Recursive Routing, check ping 1.1.1.1 instead of ISP1 IP" distance=10 gateway=1.1.1.1 check-gateway=ping
add comment="C - ISP2 is alternative Gateway" distance=20 gateway=$isp2gateway
