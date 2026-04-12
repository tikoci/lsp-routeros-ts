# Source: https://forum.mikrotik.com/t/buying-rb1100ahx4-dude-edition-questions-about-firewall/148996/4
# Post author: @rextended
# Extracted from: code-block

/interface list
add name=WAN comment=defconf
add name=LAN comment=defconf

/interface list member
add list=WAN interface=ether1 comment=defconf
add list=LAN interface=bridge comment=defconf

/ip firewall filter
add chain=input   action=accept               connection-state=established,related,untracked     comment="defconf: accept established,related,untracked"
add chain=input   action=drop                 connection-state=invalid                           comment="defconf: drop invalid"
add chain=input   action=accept               protocol=icmp                                      comment="defconf: accept ICMP"
add chain=input   action=accept               src-address=127.0.0.1  dst-address=127.0.0.1       comment="defconf: accept to local loopback (for CAPsMAN)"
add chain=input   action=drop                 in-interface-list=!LAN                             comment="defconf: drop all not coming from LAN"
add chain=forward action=accept               ipsec-policy=in,ipsec                              comment="defconf: accept in ipsec policy"
add chain=forward action=accept               ipsec-policy=out,ipsec                             comment="defconf: accept out ipsec policy"
add chain=forward action=fasttrack-connection connection-state=established,related               comment="defconf: fasttrack"
add chain=forward action=accept               connection-state=established,related,untracked     comment="defconf: accept established,related, untracked"
add chain=forward action=drop                 connection-state=invalid                           comment="defconf: drop invalid"
add chain=forward action=drop                 in-interface-list=WAN connection-nat-state=!dstnat comment="defconf: drop all from WAN not DSTNATed"

/ip firewall nat
add chain=srcnat action=masquerade out-interface-list=WAN ipsec-policy=out,none comment="defconf: masquerade"
