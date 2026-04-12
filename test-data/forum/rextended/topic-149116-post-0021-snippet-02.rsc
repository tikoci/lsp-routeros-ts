# Source: https://forum.mikrotik.com/t/classless-routes-not-being-added-by-dhcp-client/149116/21
# Post author: @rextended
# Extracted from: code-block

/ip dhcp-client
... script=":global dhcpClientIF \$interface ; :global dhcpClientCR (\$\"lease-options\"->\"121\")" ...
