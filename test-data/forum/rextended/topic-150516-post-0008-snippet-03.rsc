# Source: https://forum.mikrotik.com/t/dual-wan-failover-script-ping-command/150516/8
# Post author: @rextended
# Extracted from: code-block

/ip dns
set servers=1.1.1.1,8.8.8.8

/ip route
add comment="A - 1.1.1.1 must be reachable only from ISP1" distance=1 dst-address=1.1.1.1/32 gateway=2.3.4.5 scope=10
add comment="B - Recursive Routing, check ping 1.1.1.1 instead of ISP IP" distance=10 gateway=1.1.1.1 check-gateway=ping
add comment="C - ISP2 is alternative Gateway" distance=20 gateway=6.7.8.9
