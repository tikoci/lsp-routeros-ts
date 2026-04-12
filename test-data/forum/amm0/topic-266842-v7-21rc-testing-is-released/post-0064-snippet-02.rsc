# Source: https://forum.mikrotik.com/t/v7-21rc-testing-is-released/266842/64
# Topic: V7.21rc [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

Choose bridge interface that is your LAN. Certain apps provide best experience 
when run in LAN - they can be autodiscovered for example. 

lan bridge: none
interrupted
[admin@MikroTik] > /interface/bridge/print 
Flags: D - dynamic; X - disabled, R - running 
 0  R name="bridge1" mtu=auto actual-mtu=1500 l2mtu=65535 arp=enabled ...
