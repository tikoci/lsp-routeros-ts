# Source: https://forum.mikrotik.com/t/classless-routes-not-being-added-by-dhcp-client/149116/27
# Post author: @rextended
# Extracted from: code-block

:if ($gatpart = 0.0.0.0) do={ :set gatpart $dhcpClientIF }

:put "$[$str2ip $ippart]/$actualnum->$gatpart"
