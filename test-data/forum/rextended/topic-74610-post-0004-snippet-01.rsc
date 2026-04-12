# Source: https://forum.mikrotik.com/t/script-find-where-routing-mark-stops-work-routeros6-7/74610/4
# Post author: @rextended
# Extracted from: code-block

:put [/ip route find dst-address=0.0.0.0/0 (routing-mark)."" = ""]
