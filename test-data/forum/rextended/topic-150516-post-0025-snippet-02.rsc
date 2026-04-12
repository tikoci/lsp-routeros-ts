# Source: https://forum.mikrotik.com/t/dual-wan-failover-script-ping-command/150516/25
# Post author: @rextended
# Extracted from: code-block

:global newIP [:tostr $"local-address"]

/ip fire conn
:foreach idc in=[find where timeout>60 and (!(reply-dst-address~$newIP))] do={
 remove [find where .id=$idc]
}
