# Source: https://forum.mikrotik.com/t/wan-load-balancing-between-2-isps-one-with-cgnat-and-another-in-bridge-mode-real-ipv4-address/150195/12
# Post author: @rextended
# Extracted from: code-block

/ip route
set [find where comment~"ISP1"] gateway=$"gateway-address"
