# Source: https://forum.mikrotik.com/t/buying-rb1100ahx4-dude-edition-questions-about-firewall/148996/36
# Post author: @rextended
# Extracted from: code-block

7.21: filter add chain=input action=accept                       dst-address=127.0.0.1                 comment="defconf: accept to local loopback (for CAPsMAN)"
7.22: filter add chain=input action=accept src-address=127.0.0.1 dst-address=127.0.0.1 in-interface=lo comment="defconf: accept to local loopback (for CAPsMAN)"

7.21: filter add chain=forward action=drop connection-state=new connection-nat-state=!dstnat in-interface-list=WAN comment="defconf: drop all from WAN not DSTNATed"
7.22: filter add chain=forward action=drop                      connection-nat-state=!dstnat in-interface-list=WAN comment="defconf: drop all from WAN not DSTNATed"
