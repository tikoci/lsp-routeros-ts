# Source: https://forum.mikrotik.com/t/option39-dhcpv6-client/151933/5
# Post author: @rextended
# Extracted from: code-block

/ipv6 dhcp-client option
set [find where code=39] value=[$fqdn2encdns www.thisismydomainname.net]
