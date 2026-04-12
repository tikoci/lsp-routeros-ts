# Source: https://forum.mikrotik.com/t/classless-routes-not-being-added-by-dhcp-client/149116/21
# Post author: @rextended
# Extracted from: code-block

/ip dhcp-server option
add code=121 name=Classless-Route value=0x20C0A8640100000000202278FFF40000000000647FFF05
/ip dhcp-server network
add ... dhcp-option=Classless-Route ...
