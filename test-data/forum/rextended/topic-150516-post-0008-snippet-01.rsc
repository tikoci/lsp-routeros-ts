# Source: https://forum.mikrotik.com/t/dual-wan-failover-script-ping-command/150516/8
# Post author: @rextended
# Extracted from: code-block

/ip route
set [find where comment~"ISP1"] gateway=$"gateway-address"
