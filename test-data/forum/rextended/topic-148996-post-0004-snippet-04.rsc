# Source: https://forum.mikrotik.com/t/buying-rb1100ahx4-dude-edition-questions-about-firewall/148996/4
# Post author: @rextended
# Extracted from: code-block

/interface list
add name=WAN comment=defconf
add name=LAN comment=defconf

/interface list member
add list=WAN interface=ether1 comment=defconf
add list=LAN interface=bridge comment=defconf

/ipv6 firewall address-list
add list=bad_ipv6 address=::/128            comment="defconf: unspecified address"
add list=bad_ipv6 address=::1/128           comment="defconf: lo"
add list=bad_ipv6 address=fec0::/10         comment="defconf: site-local"
add list=bad_ipv6 address=::ffff:0.0.0.0/96 comment="defconf: ipv4-mapped"
add list=bad_ipv6 address=::/96             comment="defconf: ipv4 compat"
add list=bad_ipv6 address=100::/64          comment="defconf: discard only "
add list=bad_ipv6 address=2001:db8::/32     comment="defconf: documentation"
add list=bad_ipv6 address=2001:10::/28      comment="defconf: ORCHID"
add list=bad_ipv6 address=3ffe::/16         comment="defconf: 6bone"

/ipv6 firewall filter
add chain=input   action=accept               connection-state=established,related,untracked   comment="defconf: accept established,related,untracked"
add chain=input   action=drop                 connection-state=invalid                         comment="defconf: drop invalid"
add chain=input   action=accept               protocol=icmpv6                                  comment="defconf: accept ICMPv6"
add chain=input   action=accept               protocol=udp dst-port=33434-33534                comment="defconf: accept UDP traceroute"
add chain=input   action=accept               protocol=udp dst-port=546 src-address=fe80::/10  comment="defconf: accept DHCPv6-Client prefix delegation."
add chain=input   action=accept               protocol=udp dst-port=500,4500                   comment="defconf: accept IKE"
add chain=input   action=accept               protocol=ipsec-ah                                comment="defconf: accept ipsec AH"
add chain=input   action=accept               protocol=ipsec-esp                               comment="defconf: accept ipsec ESP"
add chain=input   action=accept               ipsec-policy=in,ipsec                            comment="defconf: accept all that matches ipsec policy"
add chain=input   action=drop                 in-interface-list=!LAN                           comment="defconf: drop everything else not coming from LAN"
# fasttrack6 only on 7.18 and up
add chain=forward action=fasttrack-connection connection-state=established,related             comment="defconf: fasttrack6"
add chain=forward action=accept               connection-state=established,related,untracked   comment="defconf: accept established,related,untracked" 
add chain=forward action=drop                 connection-state=invalid                         comment="defconf: drop invalid"
add chain=forward action=drop                 src-address-list=bad_ipv6                        comment="defconf: drop packets with bad src ipv6"
add chain=forward action=drop                 dst-address-list=bad_ipv6                        comment="defconf: drop packets with bad dst ipv6"
add chain=forward action=drop                 protocol=icmpv6 hop-limit=equal:1                comment="defconf: rfc4890 drop hop-limit=1"
add chain=forward action=accept               protocol=icmpv6                                  comment="defconf: accept ICMPv6"
add chain=forward action=accept               protocol=139                                     comment="defconf: accept HIP"
add chain=forward action=accept               protocol=udp dst-port=500,4500                   comment="defconf: accept IKE"
add chain=forward action=accept               protocol=ipsec-ah                                comment="defconf: accept ipsec AH"
add chain=forward action=accept               protocol=ipsec-esp                               comment="defconf: accept ipsec ESP"
add chain=forward action=accept               ipsec-policy=in,ipsec                            comment="defconf: accept all that matches ipsec policy"
add chain=forward action=drop                 in-interface-list=!LAN                           comment="defconf: drop everything else not coming from LAN"
